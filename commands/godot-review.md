---
description: "완성된 Godot 게임을 UX/게임디자인/기술 3관점으로 병렬 리뷰. 코드를 수정하지 않고 평가만 수행."
argument-hint: "[프로젝트 경로 (기본: 자동 탐지)]"
---

# /godot-review — 다관점 게임 리뷰

## 사용법
```
/godot-review
/godot-review <project-path>
```

## 동작

3명의 전문가 페르소나가 게임을 독립적으로 평가합니다:
- **UX 디자이너** — 컨트롤, 시각 명확성, 온보딩, 피드백, 접근성
- **게임 디자이너** — 재미, 밸런스, 난이도 곡선, 리플레이성, Juice
- **기술 리뷰어 (Godot 전문)** — GDScript 성능, 코드 품질, 에러 핸들링, 씬 구조, 노드 수명주기

## 실행 순서

1. 공통 규칙 로드
   ```
   Read ${CLAUDE_PLUGIN_ROOT}/rules/shared-rules.md
   ```

2. 리뷰 스킬 로드 및 실행
   ```
   Read ${CLAUDE_PLUGIN_ROOT}/skills/godot-review/SKILL.md
   ```

3. 스킬의 프로세스를 따라 실행:
   - 인터랙티브 테스트로 스크린샷 확보
   - 3개 Agent 병렬 호출 (UX, 게임디자인, 기술)
   - 결과 통합 → `reviews/review-dashboard.md`
   - 사용자에게 요약 보고

## 출력
- `reviews/review-dashboard.md` — 통합 리뷰 대시보드

## 예시
```
/godot-review
/godot-review my-space-game
```
