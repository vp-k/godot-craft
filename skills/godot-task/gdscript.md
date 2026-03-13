# GDScript Quick Reference (Godot 4)

## 기본 구조

```gdscript
extends Node2D

class_name MyClass  # 전역 등록 (선택)

# 시그널
signal health_changed(new_value: int)
signal died

# 상수
const MAX_HEALTH: int = 100

# Export (에디터에서 편집 가능)
@export var speed: float = 200.0
@export var health: int = MAX_HEALTH
@export_range(0, 100) var volume: int = 50
@export_enum("Easy", "Normal", "Hard") var difficulty: int = 1
@export_file("*.tscn") var next_scene: String
@export_group("Movement")
@export var jump_force: float = -400.0

# Onready (씬 트리 준비 후 초기화)
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer

# 일반 변수
var score: int = 0
var is_alive: bool = true
```

## 라이프사이클

```gdscript
func _ready() -> void:
    # 씬 트리에 추가된 직후
    pass

func _process(delta: float) -> void:
    # 매 프레임 (렌더링)
    pass

func _physics_process(delta: float) -> void:
    # 매 물리 프레임 (고정 타임스텝)
    pass

func _input(event: InputEvent) -> void:
    # 모든 입력 이벤트
    pass

func _unhandled_input(event: InputEvent) -> void:
    # 다른 노드에서 처리 안 된 입력
    pass

func _enter_tree() -> void:
    pass

func _exit_tree() -> void:
    pass
```

## 입력 처리

```gdscript
# 액션 기반 (권장)
if Input.is_action_pressed("move_right"):
    velocity.x = speed
if Input.is_action_just_pressed("jump"):
    velocity.y = jump_force
if Input.is_action_just_released("shoot"):
    fire()

# 축 입력
var direction = Input.get_axis("move_left", "move_right")
var move_vector = Input.get_vector("left", "right", "up", "down")

# 이벤트 기반
func _input(event):
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            shoot(event.position)
```

## 이동 패턴

### CharacterBody2D (탑다운)
```gdscript
func _physics_process(delta: float) -> void:
    var direction = Input.get_vector("left", "right", "up", "down")
    velocity = direction * speed
    move_and_slide()
```

### CharacterBody2D (플랫포머)
```gdscript
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_VELOCITY
    var direction = Input.get_axis("left", "right")
    velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * delta * 10)
    move_and_slide()
```

### RigidBody2D
```gdscript
func _physics_process(delta: float) -> void:
    var direction = Input.get_vector("left", "right", "up", "down")
    apply_central_force(direction * force_amount)
```

## 노드 관리

```gdscript
# 자식 노드 참조
var player = $Player           # 직접 자식
var sprite = $Player/Sprite2D  # 경로
var hud = %HUD                 # 유니크 이름 (씬에서 설정)

# 인스턴스 생성
var enemy_scene = preload("res://scenes/enemy.tscn")
var enemy = enemy_scene.instantiate()
enemy.position = Vector2(100, 200)
add_child(enemy)

# 삭제
enemy.queue_free()

# 그룹
add_to_group("enemies")
var enemies = get_tree().get_nodes_in_group("enemies")
get_tree().call_group("enemies", "take_damage", 10)
```

## 시그널

```gdscript
# 선언
signal score_changed(new_score: int)

# 발신
score_changed.emit(score)

# 수신 (코드)
player.score_changed.connect(_on_score_changed)
func _on_score_changed(new_score: int) -> void:
    label.text = str(new_score)

# 수신 (람다)
button.pressed.connect(func(): print("clicked"))

# 해제
player.score_changed.disconnect(_on_score_changed)
```

## 타이머

```gdscript
# 원샷
await get_tree().create_timer(1.0).timeout

# Timer 노드
@onready var timer: Timer = $Timer
func _ready():
    timer.wait_time = 2.0
    timer.one_shot = false
    timer.timeout.connect(_on_timeout)
    timer.start()
```

## 씬 전환

```gdscript
# 전환
get_tree().change_scene_to_file("res://scenes/level_2.tscn")

# 리로드
get_tree().reload_current_scene()

# 종료
get_tree().quit()

# 일시정지
get_tree().paused = true  # process_mode = PROCESS_MODE_ALWAYS인 노드만 동작
```

## 유용한 수학

```gdscript
# 보간
var smoothed = lerp(current, target, delta * 10)
var smoothed_v = current.lerp(target, delta * 10)

# 거리
var dist = position.distance_to(target.position)

# 방향
var dir = position.direction_to(target.position)

# 각도
var angle = position.angle_to_point(target.position)

# 랜덤
var rand_int = randi_range(1, 10)
var rand_float = randf_range(0.5, 1.5)

# 클램프
health = clamp(health, 0, MAX_HEALTH)
```

## 오디오

```gdscript
# 2D 위치 사운드
@onready var sfx: AudioStreamPlayer2D = $SFX
sfx.play()

# 글로벌 사운드 (BGM)
@onready var bgm: AudioStreamPlayer = $BGM
bgm.play()

# 볼륨 (dB)
bgm.volume_db = -10.0
```

## 애니메이션

```gdscript
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# AnimationPlayer
anim.play("walk")
anim.play("idle")
await anim.animation_finished

# AnimatedSprite2D
sprite.play("run")
sprite.flip_h = velocity.x < 0
```

## UI

```gdscript
# Label
$Label.text = "Score: %d" % score

# ProgressBar
$HealthBar.value = health

# Button
$Button.pressed.connect(_on_button_pressed)

# 마우스 입력 투과
# Control 노드: mouse_filter = MOUSE_FILTER_IGNORE
```
