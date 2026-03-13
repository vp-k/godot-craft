---
name: implementation
description: "Phase 2 — PLAN.md 태스크를 순서대로 구현. godot-task 스킬로 각 태스크 실행, compile-check + 스크린샷"
---

# Phase 2: Implementation

## 개요

PLAN.md의 태스크를 DAG 순서대로 구현합니다. 각 태스크는 godot-task 스킬을 사용합니다.

## 태스크 루프

```
반복 {
    1. 다음 태스크 가져오기
    2. godot-task 스킬로 구현
    3. compile-check
    4. 스크린샷 캡처 (선택)
    5. 태스크 상태 업데이트
    6. 에러 → 에스컬레이션
} until NO_TASKS_READY
```

### Step 1: 다음 태스크 확인

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh next-task
```

`NO_TASKS_READY` 반환 시 → impl-gate로 이동.

### Step 2: 태스크 시작

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh update-task <N> in_progress
```

### Step 3: godot-task 스킬 로드 + 실행

```
Read ${CLAUDE_PLUGIN_ROOT}/skills/godot-task/SKILL.md
```

godot-task 스킬이 태스크의 실제 구현을 담당합니다:
- GDScript 코드 작성 (스텁을 실제 구현으로)
- 씬 수정/추가
- 사운드 연결
- 입력 처리

### Step 4: 컴파일 검증

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh compile-check
```

실패 시 → 에러 기록 + 에스컬레이션:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh record-error \
  --file "<파일>" --type "compile" --msg "<에러>" --level L0 --action "<수정>"
```

### Step 5: 스크린샷 캡처 (선택)

게임 실행이 의미 있는 시점(플레이어 이동, 적 출현 등)에서:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/tools/capture.sh screenshot
```

### Step 6: 태스크 완료

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh update-task <N> done
```

### Step 7: 에러 에스컬레이션

compile-check 실패 시 L0~L5 에스컬레이션:

```
L0 (즉시 수정, 3회): 오타, 경로, 구문 에러 직접 수정
L1 (다른 방법, 3회): 같은 설계, 다른 구현 (예: 다른 노드 타입)
L2 (근본 분석, 1회): Godot API 문서 확인, 아키텍처 재검토
    → Read ${CLAUDE_PLUGIN_ROOT}/skills/godot-task/quirks.md
    → Read ${CLAUDE_PLUGIN_ROOT}/skills/godot-task/gdscript.md
L3 (다른 접근법, 3회): 씬 구조 재설계, 다른 패턴
L4 (범위 축소, 1회): 최소 동작 버전
L5 (사용자 개입): 선택지 제시
```

## 구현 원칙

### GDScript 코드 품질
- `@onready`, `@export` 사용 (Godot 4 문법)
- 시그널은 STRUCTURE.md의 시그널 맵 준수
- 물리 관련은 `_physics_process`에서
- 입력은 STRUCTURE.md의 입력 액션 사용
- `move_and_slide()` 호출 전 velocity 설정

### 씬 수정 원칙
- 기존 씬에 노드 추가 시 `.tscn` 직접 편집
- `ext_resource` 참조 시 path는 `res://` 기준
- 씬 간 의존은 `preload()` 또는 `load()`

### 사운드 연결
- `AudioStreamPlayer2D` (2D) 또는 `AudioStreamPlayer3D` (3D)
- BGM은 `AudioStreamPlayer` (논포지셔널)
- `autoplay` 주의: BGM만 autoplay, SFX는 코드로 `play()`

## impl-gate

모든 태스크 완료 후:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh impl-gate
```

## 완료 조건

- [x] 모든 태스크 status=done
- [x] compile-check 통과
- [x] impl-gate 통과
