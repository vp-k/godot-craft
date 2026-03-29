---
description: "Godot 게임 인터랙티브 테스트 실행. 입력 주입 + 상태 검증 + 스크린샷 캡처."
argument-hint: "[시나리오 이름 (기본: 전체 배치 테스트)]"
---

# /godot-test — 인터랙티브 테스트

게임에 자동화된 입력을 주입하고, 게임 상태를 검증하고, 스크린샷을 캡처합니다.

## 사용법
```
/godot-test
/godot-test idle
/godot-test idle,start-game,basic-movement
```

## 동작

1. 공통 규칙 + 테스팅 규칙 로드
   ```
   Read ${CLAUDE_PLUGIN_ROOT}/rules/shared-rules.md
   Read ${CLAUDE_PLUGIN_ROOT}/rules/testing-rules-godot.md
   ```

2. 테스팅 스킬 로드 및 실행
   ```
   Read ${CLAUDE_PLUGIN_ROOT}/skills/godot-testing/SKILL.md
   ```

3. 시나리오 실행:
   - 인수 없음 → 전체 시나리오 배치 테스트
   - 시나리오 이름 → 해당 시나리오만 실행
   - 콤마 구분 → 여러 시나리오 배치 실행

4. 결과 분석:
   - 스크린샷 시각 검증 (Read 도구)
   - 상태 JSON 확인
   - 에러 확인 및 수정 (최대 5회)

## 시나리오 목록
- `idle` — 아이들 안정성
- `start-game` — 게임 시작 전이
- `basic-movement` — 4방향 이동
- `jump-test` — 점프 메커닉
- `move-and-jump` — 복합 입력
- `pause-resume` — 일시정지/재개
- `boundary-test` — 경계 충돌
- `stress-test` — 입력 스트레스

## 출력
- `test_output/shot-{scenario}.png` — 스크린샷
- `test_output/state-{scenario}.json` — 게임 상태
- `test_output/result-{scenario}.json` — 테스트 결과
- `test_output/batch-summary.json` — 배치 요약
