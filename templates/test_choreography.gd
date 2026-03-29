## test_choreography.gd — Autoload 템플릿
## JSON 시나리오를 읽어 입력 이벤트를 자동 주입합니다.
## game-develop의 Playwright 입력 주입 + advanceTime()에 대응하는 Godot 구현.
##
## 사용법:
##   1. 이 파일을 프로젝트에 복사 (res://autoloads/test_choreography.gd)
##   2. Project Settings → AutoLoad에 등록 (이름: TestChoreography)
##   3. 커맨드라인 인수로 시나리오 전달:
##      godot --path <project> -- --test-scenario res://test_scenarios/idle.json
##
## 테스트 러너(godot-test-runner.sh)가 자동으로 이 스크립트를 주입합니다.

extends Node

## 시나리오 완료 시 발생
signal scenario_completed(scenario_name: String, passed: bool)

## 설정
const OUTPUT_DIR := "user://test_output/"
const SCREENSHOT_DELAY_FRAMES := 2

## 시나리오 데이터
var scenario_name: String = ""
var steps: Array = []
var assertions: Dictionary = {}
var total_frames: int = 0

## 실행 상태
var current_step: int = -1
var frame_counter: int = 0
var global_frame: int = 0
var is_running: bool = false
var _screenshot_pending: bool = false
var _screenshot_delay: int = 0
var _finishing: bool = false

## 에러 수집
var errors: Array = []
var _original_print_error: Callable


func _ready() -> void:
	# 커맨드라인에서 시나리오 경로 읽기
	var args := OS.get_cmdline_user_args()
	var scenario_path := ""
	for i in range(args.size()):
		if args[i] == "--test-scenario" and i + 1 < args.size():
			scenario_path = args[i + 1]
		elif args[i] == "--test-name" and i + 1 < args.size():
			scenario_name = args[i + 1]

	if scenario_path.is_empty():
		return

	# 출력 디렉토리 생성
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUTPUT_DIR)
	)

	# 시나리오 로드
	if not _load_scenario(scenario_path):
		_report_error("Failed to load scenario: %s" % scenario_path)
		_save_results(false)
		get_tree().quit(1)
		return

	# 1프레임 대기 후 시작 (씬 초기화 완료 대기)
	await get_tree().process_frame
	await get_tree().process_frame
	is_running = true
	current_step = 0
	frame_counter = 0
	print("[TestChoreography] Starting scenario: %s (%d steps, %d total frames)"
		% [scenario_name, steps.size(), total_frames])


func _process(_delta: float) -> void:
	if not is_running or _finishing:
		return

	# 스크린샷 대기 중
	if _screenshot_pending:
		_screenshot_delay -= 1
		if _screenshot_delay <= 0:
			_finishing = true
			_do_capture_and_finish()
		return

	# 모든 스텝 완료
	if current_step >= steps.size():
		_on_scenario_complete()
		return

	# 같은 프레임에 여러 스텝이 있으면 모두 실행 (CODE-MEDIUM-008 fix)
	while current_step < steps.size():
		var step: Dictionary = steps[current_step]
		var step_frame: int = step.get("frame", 0)
		if global_frame >= step_frame:
			_execute_step(step)
			current_step += 1
		else:
			break

	global_frame += 1

	# 총 프레임 초과 시 종료
	if total_frames > 0 and global_frame >= total_frames:
		_on_scenario_complete()


func _load_scenario(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return false

	var json_text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_text)
	if parsed == null:
		return false

	if parsed is Dictionary:
		steps = parsed.get("steps", [])
		assertions = parsed.get("assertions", {})
		total_frames = parsed.get("frames", 0)
		if scenario_name.is_empty():
			scenario_name = parsed.get("name", "unnamed")
	elif parsed is Array:
		steps = parsed

	# 프레임 기반 정렬 (이미 정렬되어 있어야 하지만 안전장치)
	steps.sort_custom(func(a, b): return a.get("frame", 0) < b.get("frame", 0))

	# total_frames 자동 계산 (명시되지 않은 경우)
	if total_frames == 0 and steps.size() > 0:
		var last_step: Dictionary = steps[steps.size() - 1]
		total_frames = last_step.get("frame", 0) + 60  # 마지막 스텝 + 60프레임 여유
	return true


func _execute_step(step: Dictionary) -> void:
	# 해제할 액션 (명시된 것만 — 다른 키는 유지)
	var release_actions: Array = step.get("release", [])
	for action_name in release_actions:
		if InputMap.has_action(action_name):
			Input.action_release(action_name)
		else:
			_inject_key_event(action_name, false)

	# 누를 액션
	var press_actions: Array = step.get("press", [])
	for action_name in press_actions:
		if InputMap.has_action(action_name):
			Input.action_press(action_name)
		else:
			_inject_key_event(action_name, true)

	# 마우스 클릭
	if step.has("mouse_click"):
		var click: Dictionary = step.mouse_click
		_inject_mouse_click(
			Vector2(click.get("x", 0), click.get("y", 0)),
			click.get("button", MOUSE_BUTTON_LEFT)
		)

	# 상태 스냅샷 요청
	if step.get("snapshot", false):
		_request_snapshot()


func _release_all_actions() -> void:
	for action in InputMap.get_actions():
		if Input.is_action_pressed(action):
			Input.action_release(action)


func _inject_key_event(key_name: String, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.pressed = pressed
	event.keycode = _key_name_to_keycode(key_name)
	if event.keycode != KEY_NONE:
		Input.parse_input_event(event)


func _inject_mouse_click(position: Vector2, button: int = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)

	# 릴리즈를 다음 프레임에 deferred 실행 (await 사용 안 함)
	_deferred_mouse_release = {"position": position, "button": button}


var _deferred_mouse_release: Dictionary = {}

func _physics_process(_delta: float) -> void:
	if not _deferred_mouse_release.is_empty():
		var release := InputEventMouseButton.new()
		release.position = _deferred_mouse_release.position
		release.global_position = _deferred_mouse_release.position
		release.button_index = _deferred_mouse_release.button
		release.pressed = false
		Input.parse_input_event(release)
		_deferred_mouse_release = {}


func _key_name_to_keycode(name: String) -> int:
	var map := {
		"up": KEY_UP, "down": KEY_DOWN, "left": KEY_LEFT, "right": KEY_RIGHT,
		"space": KEY_SPACE, "enter": KEY_ENTER, "escape": KEY_ESCAPE,
		"tab": KEY_TAB, "shift": KEY_SHIFT,
		"a": KEY_A, "b": KEY_B, "c": KEY_C, "d": KEY_D,
		"e": KEY_E, "f": KEY_F, "g": KEY_G, "h": KEY_H,
		"i": KEY_I, "j": KEY_J, "k": KEY_K, "l": KEY_L,
		"m": KEY_M, "n": KEY_N, "o": KEY_O, "p": KEY_P,
		"q": KEY_Q, "r": KEY_R, "s": KEY_S, "t": KEY_T,
		"u": KEY_U, "v": KEY_V, "w": KEY_W, "x": KEY_X,
		"y": KEY_Y, "z": KEY_Z,
		"1": KEY_1, "2": KEY_2, "3": KEY_3, "4": KEY_4, "5": KEY_5,
	}
	return map.get(name.to_lower(), KEY_NONE)


func _request_snapshot() -> void:
	# StateReporter가 있으면 스냅샷 요청
	var reporter := get_node_or_null("/root/StateReporter")
	if reporter and reporter.has_method("dump_scenario_state"):
		reporter.dump_scenario_state(scenario_name, current_step)


func _on_scenario_complete() -> void:
	is_running = false
	_release_all_actions()

	# 최종 상태 덤프
	_request_snapshot()

	# 스크린샷 캡처 대기
	_screenshot_pending = true
	_screenshot_delay = SCREENSHOT_DELAY_FRAMES

	print("[TestChoreography] Scenario complete: %s" % scenario_name)


## _capture_screenshot → _do_capture_and_finish (await 제거, _process에서 안전하게 호출)
func _do_capture_and_finish() -> void:
	# RenderingServer.frame_post_draw에 연결하여 다음 드로우 후 캡처
	RenderingServer.frame_post_draw.connect(_on_frame_post_draw, CONNECT_ONE_SHOT)


func _on_frame_post_draw() -> void:
	# Viewport 스크린샷
	var viewport := get_viewport()
	if viewport:
		var image := viewport.get_texture().get_image()
		if image:
			var path := OUTPUT_DIR + "shot-%s.png" % scenario_name
			var global_path := ProjectSettings.globalize_path(path)
			image.save_png(global_path)
			print("[TestChoreography] Screenshot → %s" % global_path)

	# Assertion 검증
	var passed := _run_assertions()

	# 결과 저장
	_save_results(passed)

	# 종료
	scenario_completed.emit(scenario_name, passed)
	get_tree().create_timer(0.5).timeout.connect(
		func(): get_tree().quit(0 if passed else 1)
	)


func _run_assertions() -> bool:
	if assertions.is_empty():
		return errors.is_empty()

	var reporter := get_node_or_null("/root/StateReporter")
	if not reporter or not reporter.has_method("get_state"):
		_report_error("StateReporter not available for assertions")
		return false

	var state: Dictionary = reporter.get_state()
	var all_passed := true

	for key in assertions:
		var expected = assertions[key]
		var actual = _resolve_nested_key(state, key)

		if not _check_assertion(key, actual, expected):
			all_passed = false

	return all_passed and errors.is_empty()


func _resolve_nested_key(dict: Dictionary, key: String):
	var parts := key.split(".")
	var current = dict
	for part in parts:
		if current is Dictionary and current.has(part):
			current = current[part]
		else:
			return null
	return current


func _check_assertion(key: String, actual, expected) -> bool:
	# 직접 값 비교
	if not expected is Dictionary:
		if actual != expected:
			_report_error("Assertion failed: %s = %s (expected %s)" % [key, str(actual), str(expected)])
			return false
		return true

	# 연산자 비교
	for op in expected:
		var target = expected[op]
		var passed := false
		match op:
			"eq": passed = (actual == target)
			"ne": passed = (actual != target)
			"gt": passed = (actual != null and actual > target)
			"gte": passed = (actual != null and actual >= target)
			"lt": passed = (actual != null and actual < target)
			"lte": passed = (actual != null and actual <= target)
			_: passed = true

		if not passed:
			_report_error("Assertion failed: %s %s %s (actual: %s)" % [key, op, str(target), str(actual)])
			return false
	return true


func _report_error(msg: String) -> void:
	errors.append({"message": msg, "frame": global_frame})
	push_error("[TestChoreography] %s" % msg)


func _save_results(passed: bool) -> void:
	var result := {
		"scenario": scenario_name,
		"passed": passed,
		"total_frames": global_frame,
		"errors": errors,
		"assertions_checked": assertions.size(),
	}

	var path := OUTPUT_DIR + "result-%s.json" % scenario_name
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(result, "\t"))
		file.close()
