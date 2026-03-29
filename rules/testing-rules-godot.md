# Godot Testing Rules

Godot 게임 인터랙티브 테스트의 규칙과 절차입니다.
game-develop의 `testing-rules.md`를 Godot 4 환경에 맞게 적응한 버전.

## 핵심 원칙

**스크린샷이 진실의 원천이다.** 스크린샷에 보이지 않으면 빌드에 없는 것이다.
스크린샷을 생성만 하지 말고 반드시 Read 도구로 열어서 시각적으로 확인하라.

**Godot 콘솔 에러 제로 톨러런스.** `SCRIPT ERROR`나 `ERROR`가 하나라도 발견되면 첫 번째 에러를 수정한 후 재테스트하라.

**깨진 게임은 허용되지 않는다.**

## API 존재 검증 (테스트 전 필수)

테스트 실행 전에 반드시 두 Autoload의 존재를 확인:

1. **StateReporter** (`game_state_reporter.gd`) — 없으면 게임 상태 검사 불가능
2. **TestChoreography** (`test_choreography.gd`) — 없으면 입력 자동화 불가능

확인 방법:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-test-runner.sh --check-api
```

둘 중 하나라도 없으면 `--inject-autoloads`로 주입:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-test-runner.sh --inject-autoloads --check-api
```

## 반복 제한

**최대 5회 수정-재테스트 반복.** 5회 반복 후에도 문제가 해결되지 않으면:
1. 현재까지의 시도와 결과를 정리
2. progress JSON에 미해결 이슈 기록 (errors 배열)
3. 에스컬레이션 레벨에 따라 다음 단계 결정 (shared-rules.md 참조)

## 테스트 시나리오 카테고리

### Idle
- 입력 없이 대기 — 크래시, 에러, 비정상 상태 확인
- 시나리오: `idle`

### Start Game
- `ui_accept`로 게임 시작 — 씬 전이, 게임 모드 변경 확인
- 시나리오: `start-game`

### Basic Movement
- 4방향 이동 — `move_left`/`move_right`/`move_up`/`move_down` Input Action 반응 확인
- 시나리오: `basic-movement`

### Jump Test
- 점프 액션 — `jump` Input Action, 중력, 착지 확인 (플랫포머용)
- 시나리오: `jump-test`

### Complex Input
- 복합 입력 — 이동+점프 동시 입력
- 시나리오: `move-and-jump`

### Pause/Resume
- 일시정지/재개 — `pause` Input Action으로 `SceneTree.paused` 토글
- 시나리오: `pause-resume`

### Boundary Test
- 경계 조건 — 화면/맵 끝까지 이동, 충돌 확인
- 시나리오: `boundary-test`

### Stress Test
- 빠른 교대 입력 — 입력 처리 안정성, 상태 일관성 확인
- 시나리오: `stress-test`

## 시나리오 페이로드 형식 (Godot Input Action 기반)

```json
{
  "steps": [
    {
      "frame": 0,
      "press": ["move_right", "jump"],
      "release": ["move_left"]
    },
    {
      "frame": 30,
      "mouse_click": { "x": 640, "y": 360, "button": 1 }
    },
    {
      "frame": 60,
      "snapshot": true
    }
  ],
  "frames": 120,
  "assertions": {
    "mode": "playing",
    "player.x": { "ne": 0 },
    "score": { "gte": 0 }
  }
}
```

### 필드 설명
- `frame`: 이 스텝을 실행할 프레임 번호 (0부터 시작)
- `press`: 누를 Input Action 이름 배열 (InputMap에 정의된 액션)
- `release`: 해제할 Input Action 이름 배열
- `mouse_click`: 마우스 클릭 (x, y, button)
- `snapshot`: true면 StateReporter에 상태 스냅샷 요청
- `frames`: 총 실행 프레임 수
- `assertions`: 시나리오 완료 시 상태 검증 조건

### Godot Input Action 매핑

테스트 시나리오에서 사용하는 액션 이름은 Godot Input Map에 정의된 이름과 일치해야 합니다.
일반적인 매핑:

| 액션 이름 | 용도 | 일반적인 키 |
|-----------|------|-----------|
| `move_left` | 좌측 이동 | Arrow Left, A |
| `move_right` | 우측 이동 | Arrow Right, D |
| `move_up` | 상단 이동 | Arrow Up, W |
| `move_down` | 하단 이동 | Arrow Down, S |
| `jump` | 점프 | Space |
| `attack` | 공격 | Z, LMB |
| `interact` | 상호작용 | E, Enter |
| `pause` | 일시정지 | P, Escape |
| `ui_accept` | UI 확인 | Enter, Space (Godot 내장) |
| `ui_cancel` | UI 취소 | Escape (Godot 내장) |

InputMap에 없는 액션을 `press`에 넣으면 TestChoreography가 키 이름으로 폴백하여 직접 `InputEventKey`를 주입합니다.

## Assertion 연산자

| 연산자 | 의미 | 예시 |
|--------|------|------|
| `eq` | 일치 | `"mode": { "eq": "playing" }` |
| `ne` | 불일치 | `"mode": { "ne": "menu" }` |
| `gt` | 초과 | `"score": { "gt": 0 }` |
| `gte` | 이상 | `"score": { "gte": 0 }` |
| `lt` | 미만 | `"player.y": { "lt": 500 }` |
| `lte` | 이하 | `"player.x": { "lte": 1280 }` |

값을 직접 쓰면 `eq`로 처리: `"mode": "playing"` = `"mode": { "eq": "playing" }`

## 테스트 실행 방법

### 단일 시나리오
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-test-runner.sh \
  --inject-autoloads \
  --scenario idle
```

### 배치 시나리오
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-test-runner.sh \
  --inject-autoloads \
  --scenarios idle,start-game,basic-movement,jump-test,boundary-test,stress-test
```

### 결과 파일
- `test_output/shot-{scenario}.png` — 스크린샷
- `test_output/state-{scenario}.json` — 게임 상태 JSON
- `test_output/result-{scenario}.json` — 테스트 결과 (passed/failed + 에러)
- `test_output/errors-{scenario}.json` — Godot 콘솔 에러
- `test_output/batch-summary.json` — 배치 테스트 요약

## 테스트 실패 시 대응

1. **타임아웃** → Godot이 시작 안 됨. Xvfb 확인, `--no-xvfb`로 재시도
2. **스크린샷이 없음** → Viewport 캡처 실패. Xvfb 디스플레이 확인
3. **콘솔 에러** → `errors-{scenario}.json` 확인, 첫 번째 에러부터 수정
4. **Assertion 실패** → `result-{scenario}.json`의 errors 확인, 게임 로직 수정
5. **상태 불일치** → `state-{scenario}.json`과 스크린샷 비교

## 시나리오 간 격리

각 시나리오는 Godot 프로세스를 새로 시작하여 완전히 격리됩니다.
교차 상태 오염이 없습니다.

## 게임 코드 요구사항

테스트가 올바르게 작동하려면 게임 코드가 다음을 따라야 합니다:

1. **그룹 태그**: 플레이어는 `"player"` 그룹, 적은 `"enemies"` 그룹, GameManager는 `"game_manager"` 그룹
2. **게임 모드**: GameManager에 `game_mode` 또는 `mode` 프로퍼티
3. **Input Action**: `move_left`/`move_right`/`move_up`/`move_down`/`jump` 등 표준 액션명 사용
4. **점수**: GameManager에 `score` 프로퍼티

이 규칙은 Phase 2(Implementation)의 godot-task에서 자동으로 적용됩니다.
