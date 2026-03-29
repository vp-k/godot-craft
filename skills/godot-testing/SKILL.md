---
name: godot-testing
description: "Godot 게임 인터랙티브 테스트 — 입력 주입, 상태 검증, 스크린샷 캡처를 자동화하는 테스트 스킬"
---

# Godot Testing — 인터랙티브 테스트

## 개요

게임에 자동화된 입력을 주입하고, 게임 상태를 검증하고, 스크린샷을 캡처합니다.
game-develop의 Playwright 테스트를 Godot 4에 맞게 재구현한 시스템입니다.

## 필수 참조

- **테스팅 규칙**: `rules/testing-rules-godot.md` — 반복 제한, 시나리오 카테고리, 페이로드 형식
- **시나리오 템플릿**: `templates/test-scenarios.json` — 기본 시나리오 정의
- **StateReporter**: `templates/game_state_reporter.gd` — 게임 상태 직렬화 Autoload
- **TestChoreography**: `templates/test_choreography.gd` — 입력 주입 Autoload

## 아키텍처

```
godot-test-runner.sh (오케스트레이터)
    ├── game_state_reporter.gd (Autoload) → 상태 JSON 덤프
    ├── test_choreography.gd (Autoload) → 입력 주입 + assertion
    └── test-scenarios.json → 시나리오 정의

실행 흐름:
1. Autoload 주입 → project.godot에 등록
2. 시나리오 JSON 추출 → 임시 파일
3. Godot 실행 (Xvfb) → 시나리오 자동 실행
4. 결과 수집 → 스크린샷 + state.json + errors
5. Autoload 제거 → 원상복구
```

## 워크플로우

### Step 1: 환경 확인

```bash
# Godot + jq 필수
command -v godot && command -v jq

# Linux: Xvfb 필수 (스크린샷 캡처용)
command -v Xvfb
```

### Step 2: API 존재 확인

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-test-runner.sh --check-api
```

결과가 `ready: false`이면 `--inject-autoloads` 사용.

### Step 3: 게임 코드 요구사항 확인

테스트가 올바르게 작동하려면:
- 플레이어 노드: `add_to_group("player")`
- 적 노드: `add_to_group("enemies")`
- GameManager: `add_to_group("game_manager")`, `game_mode`/`score` 프로퍼티
- Input Action: `move_left`, `move_right`, `move_up`, `move_down`, `jump` 등 표준 이름

**⚠️ 이 요구사항은 Phase 2에서 godot-task가 코드를 생성할 때 자동으로 반영해야 합니다.**

### Step 4: 시나리오 준비

기본 시나리오(`templates/test-scenarios.json`)를 사용하거나, 게임에 맞는 커스텀 시나리오를 작성합니다.

커스텀 시나리오 예시 (슈팅 게임):
```json
{
  "scenarios": {
    "shoot-enemy": {
      "description": "게임 시작 후 적 방향으로 이동하며 공격",
      "frames": 180,
      "steps": [
        { "frame": 0, "press": ["ui_accept"] },
        { "frame": 3, "release": ["ui_accept"] },
        { "frame": 20, "press": ["move_right"] },
        { "frame": 40, "press": ["attack"] },
        { "frame": 42, "release": ["attack"] },
        { "frame": 60, "release": ["move_right"] }
      ],
      "assertions": {
        "mode": "playing",
        "score": { "gte": 0 }
      }
    }
  }
}
```

### Step 5: 테스트 실행

#### 단일 시나리오
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-test-runner.sh \
  --inject-autoloads \
  --scenario idle \
  --output-dir test_output
```

#### 배치 테스트 (전체 시나리오)
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-test-runner.sh \
  --inject-autoloads \
  --scenarios idle,start-game,basic-movement \
  --output-dir test_output
```

#### 커스텀 시나리오 파일 사용
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-test-runner.sh \
  --inject-autoloads \
  --scenarios-file custom-scenarios.json \
  --scenarios shoot-enemy,dodge-test
```

### Step 6: 결과 분석

#### 6a. 스크린샷 시각 검증 ⚠️ 중요
**반드시 Read 도구로 스크린샷 이미지 파일을 열어서 시각적으로 확인합니다.**
```
Read test_output/shot-idle.png
Read test_output/shot-start-game.png
Read test_output/shot-basic-movement.png
```
- 화면에 보여야 할 것이 모두 보이는가?
- 게임이 정상적으로 렌더링되는가?
- 스크린샷이 검은색/빈 화면이면 Xvfb/렌더링 문제

#### 6b. 상태 JSON 확인
```
Read test_output/state-start-game.json
```
- 게임 모드가 예상대로 변경되었는가?
- 플레이어 위치가 움직였는가?
- 점수가 올바른가?

#### 6c. 에러 확인
```
Read test_output/errors-{scenario}.json
```
- 에러가 있으면 **첫 번째 에러만** 수정
- 수정 후 재테스트 (Step 5로)

#### 6d. 배치 요약 확인
```
Read test_output/batch-summary.json
```
- `passed`/`total` 비율 확인
- FAIL 시나리오 식별

### Step 7: 반복 (최대 5회)

에러 또는 assertion 실패 시:
1. 첫 번째 이슈만 수정
2. 재테스트
3. **최대 5회 반복** 후 미해결 시 progress에 기록하고 보고

## Phase 2 통합

Implementation Phase에서 매 태스크 완료 후:
1. `compile-check` 통과 확인
2. 관련 시나리오 테스트 실행 (예: 이동 구현 → `basic-movement`)
3. 스크린샷 + 상태 확인

## Phase 3 전 통합

VQA Phase 시작 전:
1. 전체 시나리오 배치 테스트 실행
2. 모든 시나리오 PASS 확인
3. FAIL 시 수정 후 재실행

## 완료 조건

- [x] 모든 기본 시나리오 실행 완료
- [x] 스크린샷 시각 검증 완료
- [x] 콘솔 에러 0건
- [x] Assertion 모두 통과
- [x] batch-summary.json의 failed = 0
