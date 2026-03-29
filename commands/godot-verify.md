---
description: "최종 검증 실행. Phase 5만 단독 실행. compile-check + 에셋/씬 무결성 + DoD 체크."
argument-hint: "[프로젝트 경로 (기본: 자동 탐지)]"
---

# /godot-verify — 최종 검증

Phase 5(Verification)만 단독 실행합니다.
모든 기계적 검증을 수행하고 DoD 체크리스트를 완성합니다.

## 사용법
```
/godot-verify
/godot-verify my-space-game
```

## 동작

1. 공통 규칙 로드
   ```
   Read ${CLAUDE_PLUGIN_ROOT}/rules/shared-rules.md
   ```

2. Verification 스킬 로드 및 실행
   ```
   Read ${CLAUDE_PLUGIN_ROOT}/skills/verification/SKILL.md
   ```

3. 검증 항목:
   - `compile-check` — GDScript 컴파일 검증
   - `asset-integrity` — 에셋 참조 무결성
   - `scene-integrity` — 씬 참조 검증
   - `find-debug-code` — 디버그 코드 잔류 확인
   - `collision-setup` — 충돌 레이어 검증
   - DoD 체크리스트 완성

## 출력
- progress JSON의 `dod` 체크리스트 업데이트
- 검증 결과 요약 보고
