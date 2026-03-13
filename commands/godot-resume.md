---
description: "중단된 Godot 게임 프로젝트를 이어서 진행. progress 파일을 읽고 중단된 Phase/태스크부터 재개"
argument-hint: "[progress 파일 경로 (기본: .claude-godot-progress.json)]"
---

# Godot Resume — 중단된 프로젝트 재개

## 실행 순서

### 1. 공통 규칙 로드

```
Read ${CLAUDE_PLUGIN_ROOT}/rules/shared-rules.md
```

### 2. 상태 확인

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh status
```

### 3. 핸드오프 읽기

progress 파일의 `handoff` 필드에서:
- `completedInThisIteration`: 이전에 완료한 작업
- `nextSteps`: 지금 시작할 작업
- `keyDecisions`: 유지할 설계 결정
- `warnings`: 주의사항

### 4. Ralph Loop 재설정

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh init-ralph "MAKE_WITH_GODOT_COMPLETE" ".claude-godot-progress.json"
```

### 5. 해당 Phase 스킬 로드 + 재개

현재 Phase(`currentPhase`)에 해당하는 스킬을 Read로 로드하고, 중단된 지점부터 재개합니다.

| currentPhase | 스킬 |
|-------------|------|
| phase_0 | `Read ${CLAUDE_PLUGIN_ROOT}/skills/concept-planning/SKILL.md` |
| phase_1 | `Read ${CLAUDE_PLUGIN_ROOT}/skills/scaffold-assets/SKILL.md` |
| phase_2 | `Read ${CLAUDE_PLUGIN_ROOT}/skills/implementation/SKILL.md` |
| phase_3 | `Read ${CLAUDE_PLUGIN_ROOT}/skills/visual-qa-fix/SKILL.md` |
| phase_4 | `Read ${CLAUDE_PLUGIN_ROOT}/skills/polish-present/SKILL.md` |
| phase_5 | `Read ${CLAUDE_PLUGIN_ROOT}/skills/verification/SKILL.md` |

### 6. 이후는 make-game.md와 동일한 흐름

Phase 전이 → 게이트 → 다음 Phase → ... → `<promise>MAKE_WITH_GODOT_COMPLETE</promise>`
