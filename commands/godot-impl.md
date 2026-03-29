---
description: "PLAN.md의 특정 태스크 또는 다음 ready 태스크를 구현. Phase 2 단위 실행."
argument-hint: "[태스크 ID 또는 이름 (기본: 다음 ready 태스크)]"
---

# /godot-impl — 태스크 구현

Phase 2(Implementation)의 개별 태스크를 실행합니다.
인수 없이 실행하면 다음 ready 상태 태스크를 자동으로 선택합니다.

## 사용법
```
/godot-impl
/godot-impl player_movement
/godot-impl 3
```

## 전제 조건
- Phase 1 completed (스캐폴드 완료)

## 동작

1. 공통 규칙 로드
   ```
   Read ${CLAUDE_PLUGIN_ROOT}/rules/shared-rules.md
   ```

2. Progress에서 태스크 확인
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh status
   ```

3. Implementation 스킬 로드
   ```
   Read ${CLAUDE_PLUGIN_ROOT}/skills/implementation/SKILL.md
   ```

4. godot-task 스킬로 개별 태스크 실행
   ```
   Read ${CLAUDE_PLUGIN_ROOT}/skills/godot-task/SKILL.md
   ```

5. 태스크 완료 후:
   - compile-check
   - 관련 인터랙티브 테스트 (해당되는 경우)
   - progress 업데이트
