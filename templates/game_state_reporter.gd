## game_state_reporter.gd — Autoload 템플릿
## 게임 상태를 JSON으로 직렬화하여 파일로 덤프합니다.
## game-develop의 render_game_to_text()에 대응하는 Godot 구현.
##
## 사용법:
##   1. 이 파일을 프로젝트에 복사 (res://autoloads/game_state_reporter.gd)
##   2. Project Settings → AutoLoad에 등록 (이름: StateReporter)
##   3. 게임 코드에서 그룹 태그 추가:
##      - 플레이어: add_to_group("player")
##      - 적: add_to_group("enemies")
##      - 수집물: add_to_group("collectibles")
##   4. GameManager가 있으면 add_to_group("game_manager") 추가
##
## 테스트 러너가 자동으로 이 스크립트를 주입하므로
## 수동 등록은 디버깅 용도로만 사용합니다.

extends Node

## 상태 덤프 출력 경로
const OUTPUT_DIR := "user://test_output/"
const STATE_FILE := "state.json"

## 자동 덤프 간격 (프레임). 0이면 자동 덤프 비활성
@export var auto_dump_interval: int = 0

var _frame_counter: int = 0


func _ready() -> void:
	# 출력 디렉토리 생성
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUTPUT_DIR)
	)


func _process(_delta: float) -> void:
	if auto_dump_interval > 0:
		_frame_counter += 1
		if _frame_counter >= auto_dump_interval:
			_frame_counter = 0
			dump_to_file()


## 현재 게임 상태를 Dictionary로 반환
func get_state() -> Dictionary:
	var state: Dictionary = {
		"frame": Engine.get_process_frames(),
		"time": Time.get_ticks_msec(),
		"fps": Engine.get_frames_per_second(),
		"mode": _detect_game_mode(),
		"player": _get_player_state(),
		"entities": _get_entities(),
		"score": _get_score(),
		"scene": _get_current_scene(),
	}
	return state


## JSON 문자열로 반환 (render_game_to_text 대응)
func render_to_text() -> String:
	return JSON.stringify(get_state(), "\t")


## 파일로 덤프
func dump_to_file(filename: String = STATE_FILE) -> void:
	var path := OUTPUT_DIR + filename
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(render_to_text())
		file.close()
	else:
		push_warning("[StateReporter] Failed to write state file: %s (error: %s)" % [path, str(FileAccess.get_open_error())])


## 시나리오별 스냅샷 저장
func dump_scenario_state(scenario_name: String, step_index: int) -> void:
	var filename := "state-%s-%d.json" % [scenario_name, step_index]
	dump_to_file(filename)


# ─── 내부 헬퍼 ───

func _detect_game_mode() -> String:
	# GameManager 그룹에서 모드 읽기
	var managers := get_tree().get_nodes_in_group("game_manager")
	if managers.size() > 0:
		var mgr := managers[0]
		# 일반적인 프로퍼티명 시도
		for prop_name in ["game_mode", "mode", "state", "current_state", "game_state"]:
			if mgr.get(prop_name) != null:
				return str(mgr.get(prop_name))
	# SceneTree paused 상태로 추론
	if get_tree().paused:
		return "paused"
	return "unknown"


func _get_player_state() -> Dictionary:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return {}
	var p: Node = players[0]
	var state: Dictionary = {
		"x": 0.0, "y": 0.0,
	}
	# 2D 노드
	if p is Node2D:
		state.x = p.global_position.x
		state.y = p.global_position.y
	# 3D 노드
	elif p is Node3D:
		state.x = p.global_position.x
		state.y = p.global_position.y
		state["z"] = p.global_position.z
	# 속도 (CharacterBody2D/3D)
	if p.get("velocity") != null:
		var vel = p.velocity
		state["vx"] = vel.x
		state["vy"] = vel.y
		if vel is Vector3:
			state["vz"] = vel.z
	# 바닥 접촉
	if p.has_method("is_on_floor"):
		state["on_floor"] = p.is_on_floor()
	# 체력
	for hp_name in ["health", "hp", "hit_points", "life"]:
		if p.get(hp_name) != null:
			state["health"] = p.get(hp_name)
			break
	return state


const _GROUP_TO_TYPE := {
	"enemies": "enemy",
	"collectibles": "collectible",
	"projectiles": "projectile",
	"npcs": "npc",
}

func _get_entities() -> Array:
	var result: Array = []
	for group_name in _GROUP_TO_TYPE:
		for node in get_tree().get_nodes_in_group(group_name):
			var entity: Dictionary = {
				"type": _GROUP_TO_TYPE[group_name],
				"name": node.name,
			}
			if node is Node2D:
				entity["x"] = node.global_position.x
				entity["y"] = node.global_position.y
			elif node is Node3D:
				entity["x"] = node.global_position.x
				entity["y"] = node.global_position.y
				entity["z"] = node.global_position.z
			result.append(entity)
	return result


func _get_score() -> int:
	var managers := get_tree().get_nodes_in_group("game_manager")
	if managers.size() > 0:
		var mgr := managers[0]
		for score_name in ["score", "points", "total_score"]:
			if mgr.get(score_name) != null:
				return int(mgr.get(score_name))
	return 0


func _get_current_scene() -> String:
	var current := get_tree().current_scene
	if current:
		return current.scene_file_path
	return ""
