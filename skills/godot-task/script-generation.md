# 스크립트 생성 가이드

## 스텁 → 구현 변환

스텁은 Phase 1에서 생성됩니다. Phase 2에서 `pass`를 실제 코드로 교체합니다.

### 변환 원칙

1. **시그니처 유지**: extends, signal, @export, 함수 이름은 STRUCTURE.md 기준
2. **시그널 맵 준수**: 발신/수신을 STRUCTURE.md 시그널 맵대로
3. **입력 액션 사용**: STRUCTURE.md 입력 액션 목록 참조
4. **타입 힌트**: 함수 파라미터와 반환값에 타입 지정

## 일반적인 게임 패턴

### Game Manager (싱글턴/오토로드 또는 메인 씬)

```gdscript
extends Node

signal game_started
signal game_over(is_win: bool)
signal score_changed(new_score: int)

var score: int = 0
var is_playing: bool = false

func start_game() -> void:
    score = 0
    is_playing = true
    score_changed.emit(score)
    game_started.emit()

func end_game(is_win: bool) -> void:
    is_playing = false
    game_over.emit(is_win)

func add_score(points: int) -> void:
    score += points
    score_changed.emit(score)
```

### Enemy Spawner

```gdscript
extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var max_enemies: int = 10

@onready var timer: Timer = $SpawnTimer
var enemy_count: int = 0

func _ready() -> void:
    timer.wait_time = spawn_interval
    timer.timeout.connect(_on_spawn_timer_timeout)
    timer.start()

func _on_spawn_timer_timeout() -> void:
    if enemy_count >= max_enemies:
        return
    var enemy = enemy_scene.instantiate()
    enemy.position = _get_spawn_position()
    enemy.tree_exited.connect(func(): enemy_count -= 1)
    add_child(enemy)
    enemy_count += 1

func _get_spawn_position() -> Vector2:
    # 화면 밖에서 스폰
    var viewport_size = get_viewport_rect().size
    var side = randi_range(0, 3)
    match side:
        0: return Vector2(randf_range(0, viewport_size.x), -50)  # 위
        1: return Vector2(randf_range(0, viewport_size.x), viewport_size.y + 50)  # 아래
        2: return Vector2(-50, randf_range(0, viewport_size.y))  # 왼쪽
        3: return Vector2(viewport_size.x + 50, randf_range(0, viewport_size.y))  # 오른쪽
    return Vector2.ZERO
```

### HUD

```gdscript
extends Control

@onready var score_label: Label = $ScoreLabel
@onready var health_bar: ProgressBar = $HealthBar

func update_score(new_score: int) -> void:
    score_label.text = "Score: %d" % new_score

func update_health(current: int, max_health: int) -> void:
    health_bar.max_value = max_health
    health_bar.value = current
```

### Projectile (투사체)

```gdscript
extends Area2D

@export var speed: float = 500.0
@export var damage: int = 10
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    await get_tree().create_timer(lifetime).timeout
    queue_free()

func _physics_process(delta: float) -> void:
    position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
    if body.has_method("take_damage"):
        body.take_damage(damage)
    queue_free()
```

### Health Component (재사용 가능)

```gdscript
extends Node

signal health_changed(new_health: int)
signal died

@export var max_health: int = 100
var current_health: int

func _ready() -> void:
    current_health = max_health

func take_damage(amount: int) -> void:
    current_health = max(0, current_health - amount)
    health_changed.emit(current_health)
    if current_health <= 0:
        died.emit()

func heal(amount: int) -> void:
    current_health = min(max_health, current_health + amount)
    health_changed.emit(current_health)
```

## 주의사항

- `_physics_process`에서 이동, `_process`에서 비주얼 업데이트
- `delta` 항상 곱하기 (프레임 독립적 이동)
- `queue_free()` 후 해당 노드 참조하지 않기
- `@onready` 변수는 `_ready()` 이후에만 유효
