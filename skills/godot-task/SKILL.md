---
name: godot-task
description: "단일 태스크 실행기 — GDScript 코드 작성, 씬 수정, 사운드 연결, Godot 4 함정 회피"
---

# Godot Task — 단일 태스크 실행기

## 개요

PLAN.md의 단일 태스크를 구현합니다. 스텁을 실제 코드로 채우고, 씬을 수정/연결합니다.

## 실행 순서

### Step 1: 태스크 정보 확인

progress JSON에서 현재 태스크 정보 읽기:
- `title`: 무엇을 구현하는지
- `description`: 상세 설명
- `outputs`: 생성/수정할 파일 목록
- `deps`: 의존 태스크 (이미 done)

### Step 2: 참조 파일 읽기

구현 전 반드시 읽을 파일:
1. **STRUCTURE.md** — 씬 트리, 시그널 맵, 입력 액션
2. **기존 스크립트** — 의존 태스크에서 생성된 코드
3. **quirks.md** (필요시) — Godot 4 함정 목록

```
Read ${CLAUDE_PLUGIN_ROOT}/skills/godot-task/quirks.md      # Godot 4 함정
Read ${CLAUDE_PLUGIN_ROOT}/skills/godot-task/gdscript.md    # GDScript 레퍼런스
```

### Step 3: GDScript 구현

스텁의 `pass`를 실제 코드로 교체합니다.

#### 코드 작성 규칙

**이동 (CharacterBody2D)**:
```gdscript
func _physics_process(delta: float) -> void:
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = direction * speed
    move_and_slide()
```

**플랫포머 점프**:
```gdscript
func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_force
    var direction := Input.get_axis("move_left", "move_right")
    velocity.x = direction * speed
    move_and_slide()
```

**시그널 연결** (코드에서):
```gdscript
func _ready() -> void:
    health_changed.connect(_on_health_changed)
    # 또는 다른 노드의 시그널
    %Player.died.connect(_on_player_died)
```

**시그널 연결** (씬에서):
```
[connection signal="body_entered" from="Area2D" to="." method="_on_body_entered"]
```

### Step 4: 씬 수정

기존 `.tscn`에 노드/리소스를 추가하거나, 새 씬을 생성합니다.

**새 노드 추가** (`.tscn` 편집):
```
[node name="HitBox" type="Area2D" parent="."]
[node name="CollisionShape2D" type="CollisionShape2D" parent="HitBox"]
```

**인스턴스** (씬을 다른 씬에 배치):
```
[ext_resource type="PackedScene" path="res://scenes/player.tscn" id="2"]
[node name="Player" parent="." instance=ExtResource("2")]
position = Vector2(640, 360)
```

### Step 5: 사운드 연결

```gdscript
# 씬에 AudioStreamPlayer2D 추가 후:
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound

func _jump() -> void:
    velocity.y = jump_force
    jump_sound.play()
```

### Step 6: 컴파일 검증

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh compile-check
```

에러 발생 시:
1. 에러 메시지 분석
2. `quirks.md` 참조 (알려진 함정인지)
3. 수정 후 재검증

## 보조 레퍼런스

필요시 다음을 Read로 로드:
- `${CLAUDE_PLUGIN_ROOT}/skills/godot-task/quirks.md` — Godot 4 함정 모음
- `${CLAUDE_PLUGIN_ROOT}/skills/godot-task/gdscript.md` — GDScript 레퍼런스
- `${CLAUDE_PLUGIN_ROOT}/skills/godot-task/scene-generation.md` — 씬 생성 가이드
- `${CLAUDE_PLUGIN_ROOT}/skills/godot-task/script-generation.md` — 스크립트 생성 가이드
- `${CLAUDE_PLUGIN_ROOT}/skills/godot-task/coordination.md` — 씬 간 조정
- `${CLAUDE_PLUGIN_ROOT}/skills/godot-task/capture.md` — 스크린샷 캡처
- `${CLAUDE_PLUGIN_ROOT}/skills/godot-task/visual-qa.md` — VQA 도구

## 완료 조건

- [x] 태스크의 outputs 파일 모두 생성/수정
- [x] compile-check 통과
- [x] 시그널 맵대로 연결 완료
