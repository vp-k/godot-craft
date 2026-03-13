# Godot 4 함정 모음 (Quirks)

자주 발생하는 Godot 4 실수와 해결법입니다.

## 1. Godot 3 → 4 마이그레이션 함정

| Godot 3 | Godot 4 | 실수 패턴 |
|---------|---------|-----------|
| `onready var` | `@onready var` | `@` 빠뜨림 |
| `export var` | `@export var` | `@` 빠뜨림 |
| `yield(...)` | `await ...` | 구문 변경 |
| `.connect("signal", obj, "method")` | `.signal.connect(callable)` | 연결 방식 변경 |
| `is_on_floor()` 매 프레임 | `move_and_slide()` 후에만 유효 | 호출 순서 |
| `KinematicBody2D` | `CharacterBody2D` | 노드 이름 변경 |
| `RigidBody2D` mode | `RigidBody2D` freeze | 프로퍼티 변경 |
| `Spatial` | `Node3D` | 3D 노드 이름 변경 |
| `Position2D` | `Marker2D` | 노드 이름 변경 |

## 2. CharacterBody2D 이동

```gdscript
# ❌ 잘못 — velocity 설정 전에 move_and_slide
func _physics_process(delta):
    move_and_slide()
    velocity.x = speed

# ✅ 올바른 — velocity 먼저, 그 다음 move_and_slide
func _physics_process(delta):
    velocity.x = speed
    move_and_slide()
```

## 3. is_on_floor() 타이밍

```gdscript
# ❌ 잘못 — move_and_slide 전에 체크
func _physics_process(delta):
    if is_on_floor():  # 이전 프레임의 결과
        velocity.y = jump_force
    move_and_slide()

# ✅ 이것도 작동하지만, move_and_slide 호출 직후가 가장 정확
func _physics_process(delta):
    if not is_on_floor():
        velocity.y += gravity * delta
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_force
    velocity.x = direction * speed
    move_and_slide()
```

## 4. Signal 선언과 연결

```gdscript
# 선언
signal health_changed(new_value: int)
signal died

# 발신
health_changed.emit(health)
died.emit()

# 수신 (코드에서)
player.health_changed.connect(_on_health_changed)

# 수신 (씬에서 .tscn)
[connection signal="health_changed" from="Player" to="." method="_on_health_changed"]
```

## 5. .tscn 형식 주의

```
# 반드시 첫 줄에 gd_scene 헤더
[gd_scene load_steps=N format=3]

# ext_resource는 gd_scene 바로 다음
[ext_resource type="Script" path="res://scripts/player.gd" id="1"]

# sub_resource는 ext_resource 다음
[sub_resource type="RectangleShape2D" id="RectangleShape2D_abc"]
size = Vector2(32, 64)

# node는 마지막
[node name="Root" type="Node2D"]

# connection은 맨 마지막
[connection signal="body_entered" from="Area2D" to="." method="_on_body_entered"]
```

## 6. 리소스 경로

```gdscript
# ❌ 잘못
var scene = load("scenes/enemy.tscn")

# ✅ 올바른 — 항상 res:// prefix
var scene = preload("res://scenes/enemy.tscn")
var scene = load("res://scenes/enemy.tscn")
```

## 7. Null 참조

```gdscript
# ❌ 위험 — @onready는 _ready() 전에 null
@onready var player = $Player

func some_function():
    player.position  # _ready() 전이면 null!

# ✅ 안전
func _ready():
    assert(player != null, "Player node not found")
```

## 8. Input Action 미등록

project.godot에 input action이 등록되어 있지 않으면 에러는 나지 않지만 작동 안 함.

```ini
[input]
move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":97,"location":0,"echo":false,"script":null)]
}
```

**팁**: project.godot에 직접 쓰기보다, 씬 빌더에서 InputMap.add_action + InputMap.action_add_event를 호출하는 autoload 스크립트를 만드는 것이 더 안전.

## 9. CollisionShape2D 누락

```
# ❌ CharacterBody2D에 CollisionShape 없으면 경고 + 충돌 안 됨
[node name="Player" type="CharacterBody2D"]

# ✅ 반드시 CollisionShape 자식 추가
[node name="Player" type="CharacterBody2D"]
[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
```

## 10. Area2D body_entered vs area_entered

```gdscript
# body_entered: CharacterBody2D, RigidBody2D, StaticBody2D 감지
# area_entered: 다른 Area2D 감지

# 적 총알(Area2D)이 플레이어(CharacterBody2D)와 충돌:
# → 총알의 body_entered 시그널 사용
```

## 11. Timer 사용

```gdscript
# 원샷 타이머
var timer = get_tree().create_timer(2.0)
await timer.timeout

# 반복 타이머 → Timer 노드 사용
@onready var spawn_timer: Timer = $SpawnTimer
func _ready():
    spawn_timer.timeout.connect(_on_spawn_timeout)
    spawn_timer.start()
```

## 12. 씬 전환

```gdscript
# 간단한 전환
get_tree().change_scene_to_file("res://scenes/game_over.tscn")

# packed scene 인스턴스
var enemy_scene = preload("res://scenes/enemy.tscn")
var enemy = enemy_scene.instantiate()
add_child(enemy)
```
