---
name: scaffold-assets
description: "Phase 1 — 프로젝트 스캐폴딩 + 스크립트 스텁 + 씬 생성 + 에셋 생성 (이미지/사운드/음악)"
---

# Phase 1: Scaffold & Assets

## 개요

Godot 프로젝트 구조를 생성하고, 스크립트 스텁/씬 파일을 배치하고, 에셋을 생성합니다.

## 실행 순서

### Step 1: 프로젝트 스캐폴딩

```bash
# project.godot + 디렉토리 구조
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh scaffold STRUCTURE.md

# 충돌 레이어 설정
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh collision-setup STRUCTURE.md

# UI 테마 생성
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh ui-theme

# 다국어 지원 (필요시)
# bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh i18n-scaffold "en,ko"
```

### Step 2: 스크립트 스텁 생성

STRUCTURE.md의 스크립트 목록을 기반으로 **스텁**을 생성합니다.
각 스크립트는:
- `extends` 선언
- `signal` 선언 (시그널 맵 기반)
- `@export` 변수 선언
- 주요 함수 시그니처 (`_ready`, `_process`, `_physics_process`, 커스텀)
- 함수 body는 `pass`만

```gdscript
# player.gd
extends CharacterBody2D

signal health_changed(new_health: int)
signal died

@export var speed: float = 200.0
@export var jump_force: float = -400.0

var health: int = 100

func _physics_process(delta: float) -> void:
	pass

func take_damage(amount: int) -> void:
	pass
```

### Step 3: 씬 빌더 — .tscn 파일 생성

STRUCTURE.md의 씬 트리를 기반으로 `.tscn` 파일을 생성합니다.

빌드 순서 결정:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh build-order STRUCTURE.md
```

씬 파일은 Godot의 텍스트 씬 형식:
```
[gd_scene load_steps=3 format=3 uid="uid://xxxxx"]

[ext_resource type="Script" path="res://scripts/player.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/sprites/player.png" id="2"]

[node name="Player" type="CharacterBody2D"]
script = ExtResource("1")
speed = 200.0

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_xxxxx")
```

**주의**: uid는 Godot가 자동 생성하므로, 처음에는 uid 없이 작성해도 됩니다.

### Step 4: 컴파일 검증

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh compile-check
```

에러가 있으면 수정합니다. compile-check는 scaffold-gate 이전에 반드시 통과해야 합니다.

### Step 5: 에셋 생성 프롬프트 작성

ASSETS.md의 각 에셋에 대해 **구체적인 생성 프롬프트**를 작성합니다.

프롬프트 작성 원칙:
- **게임 스타일 일관성**: reference.png의 아트 스타일 참조
- **투명 배경**: 스프라이트는 "on transparent background" 명시
- **크기/비율**: 정확한 픽셀 크기 지정
- **방향**: 캐릭터 facing 방향 명시

### Step 6: 이미지 에셋 생성

```bash
# 각 이미지 에셋 생성
python3 ${CLAUDE_PLUGIN_ROOT}/tools/asset_gen.py \
  --type image \
  --prompt "<프롬프트>" \
  --size "64x64" \
  --output "<game_name>/assets/sprites/<name>.png"

# 배경 제거 (필요시)
python3 ${CLAUDE_PLUGIN_ROOT}/tools/rembg_matting.py \
  --input "<game_name>/assets/sprites/<name>.png" \
  --output "<game_name>/assets/sprites/<name>.png"
```

### Step 7: 스프라이트시트 처리 (필요시)

스프라이트시트로 생성된 에셋은 슬라이싱:
```bash
python3 ${CLAUDE_PLUGIN_ROOT}/tools/spritesheet.py \
  --input "<spritesheet>.png" \
  --cols 4 --rows 4 \
  --output-dir "<game_name>/assets/sprites/"
```

### Step 8: 사운드(SFX) 생성

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/tools/asset_gen.py \
  --type sound \
  --prompt "<효과음 설명>" \
  --duration 0.5 \
  --output "<game_name>/assets/audio/sfx/<name>.wav"
```

### Step 9: 음악(BGM) 생성

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/tools/asset_gen.py \
  --type music \
  --prompt "<음악 설명>" \
  --duration 30 \
  --genre "<장르>" \
  --output "<game_name>/assets/audio/bgm/<name>.ogg"
```

### Step 10: 에셋 정합성 검증

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh asset-integrity
```

### Step 11: Scaffold 게이트

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh scaffold-gate
```

## 보조 스킬 참조

상세한 가이드는 다음 파일을 참조:
- `Read ${CLAUDE_PLUGIN_ROOT}/skills/scaffold-assets/scaffold.md` — 프로젝트 구조 상세
- `Read ${CLAUDE_PLUGIN_ROOT}/skills/scaffold-assets/asset-planner.md` — 에셋 계획 전략
- `Read ${CLAUDE_PLUGIN_ROOT}/skills/scaffold-assets/asset-gen.md` — 에셋 생성 도구 사용법

## 완료 조건

- [x] project.godot 생성
- [x] 디렉토리 구조 생성
- [x] 모든 스크립트 스텁 생성
- [x] 모든 .tscn 씬 파일 생성
- [x] compile-check 통과
- [x] 모든 이미지 에셋 생성
- [x] 모든 사운드 에셋 생성
- [x] 모든 음악 에셋 생성
- [x] asset-integrity 통과
- [x] scaffold-gate 통과
