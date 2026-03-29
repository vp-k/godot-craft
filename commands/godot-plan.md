---
description: "게임 콘셉트 확장 + 계획 문서(PLAN.md, STRUCTURE.md, ASSETS.md) 작성. Phase 0만 단독 실행."
argument-hint: <게임 설명 (자연어)>
---

# /godot-plan — 콘셉트 & 계획

Phase 0(Concept & Planning)만 단독 실행합니다.

## 사용법
```
/godot-plan 우주 슈팅 게임
/godot-plan 2D 플랫포머 액션 게임
```

## 동작

1. 공통 규칙 로드
   ```
   Read ${CLAUDE_PLUGIN_ROOT}/rules/shared-rules.md
   ```

2. Progress 초기화 (없으면 생성)
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh init "<game_name>" "$ARGUMENTS" "<2d|3d>"
   ```

3. Phase 0 스킬 로드 및 실행
   ```
   Read ${CLAUDE_PLUGIN_ROOT}/skills/concept-planning/SKILL.md
   ```

4. 결과물:
   - `PLAN.md` — 태스크 분해
   - `STRUCTURE.md` — 씬 트리, 스크립트, 시그널 맵
   - `ASSETS.md` — 에셋 목록 + reference.png 프롬프트
   - 사용자 승인 요청

## 이미 progress가 존재하면
Phase 0이 completed인 경우 기존 계획을 보여주고, 수정 여부를 확인합니다.
