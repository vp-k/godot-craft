# Make with Godot — 공통 규칙

모든 스킬/커맨드에 적용되는 규칙입니다.

## 검증 결과 기록 (필수)

모든 검증(컴파일/에셋/씬) 결과는 `godot-gate.sh`로 실행하고, progress JSON에 기록합니다.
증거 없는 완료 선언은 금지입니다.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh compile-check
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh asset-integrity
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh scene-integrity
```

## Ralph Loop 모드

`.claude/ralph-loop.local.md`가 존재하면 Ralph Loop 모드입니다.
- 한 iteration에서 처리할 작업을 최소화 (1~2 태스크)
- Iteration 종료 전 handoff 필드를 반드시 업데이트
- 모든 Phase 완료 + DoD 체크리스트 완료 시에만 `<promise>MAKE_WITH_GODOT_COMPLETE</promise>` 출력
- Ralph Loop 파일 생성:
  ```bash
  bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh init-ralph "MAKE_WITH_GODOT_COMPLETE" ".claude-godot-progress.json"
  ```

## Error Classification & Escalation (L0~L5)

| 레벨 | 분류 | 예시 | 예산 |
|------|------|------|------|
| L0 | 즉시 수정 | 오타, 경로 오류, 간단한 구문 에러 | 3회 |
| L1 | 다른 방법 | 같은 설계, 다른 구현 방식 | 3회 |
| L2 | 근본 원인 분석 | Godot API 문서 확인, 아키텍처 재검토 | 1회 |
| L3 | 완전히 다른 접근법 | 씬 구조 재설계, 다른 노드 타입 | 3회 |
| L4 | 범위 축소 | 최소 동작 버전으로 축소 | 1회 |
| L5 | 사용자 개입 | 선택지 제시 후 사용자 결정 | - |

에러 기록:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh record-error \
  --file "script.gd" --type "compile" --msg "에러 메시지" \
  --level L0 --action "수정 내용"
```

record-error exit code:
- exit 0: 예산 내 → 계속 시도
- exit 1: 예산 소진 → 다음 레벨로 에스컬레이트
- exit 2: L2 → 근본 원인 분석 필요
- exit 3: L5 → 사용자 개입 필요

## Phase 게이트 (필수)

Phase 전이 전 반드시 해당 게이트를 통과해야 합니다:

| Phase 전이 | 게이트 | 주요 검증 |
|------------|--------|-----------|
| 0→1 | `plan-gate` | PLAN.md + STRUCTURE.md + ASSETS.md + 태스크 로드 |
| 1→2 | `scaffold-gate` | project.godot + 씬 + 스크립트 + 컴파일 |
| 2→3 | `impl-gate` | 전 태스크 done + 컴파일 |
| 3→4 | `vqa-gate` | VQA verdict pass/acceptable |
| 4→5 | `final-gate` | 컴파일 + 에셋 + 비디오 |

## 스크립트 우선 원칙

구조적/기계적 작업은 반드시 스크립트로 처리합니다:
- 컴파일 검증 → `godot-gate.sh compile-check`
- 에셋 검증 → `godot-gate.sh asset-integrity`
- 씬 참조 → `godot-gate.sh scene-integrity`
- 태스크 상태 → `godot-gate.sh update-task`
- 프로젝트 생성 → `godot-gate.sh scaffold`

LLM은 창의적/판단적 작업만 담당합니다:
- 게임 콘셉트 설계
- GDScript 코드 작성
- 에셋 프롬프트 작성
- VQA 분석 + 수정 판단

## Godot 4 주의사항 (Quick Reference)

- `@onready` 사용 (Godot 3의 `onready`가 아님)
- `@export` 사용 (Godot 3의 `export`가 아님)
- Signal 연결: `signal_name.connect(callable)` (Godot 3의 `connect()` 함수가 아님)
- `await` 사용 (Godot 3의 `yield`가 아님)
- `super()` 사용 (Godot 3의 `.method()`가 아님)
- Node 경로: `%NodeName` (유니크 이름) 또는 `$NodeName`
- Input: `Input.is_action_pressed()`, `Input.is_action_just_pressed()`
- Physics: `_physics_process(delta)` 사용
- `.tscn` 형식: `[gd_scene load_steps=N format=3]`

## Scope Reduction (범위 축소)

**원칙**: 동작하는 게임 + 문서화된 갭 > 모든 기능 갖춘 깨진 게임

범위 축소 조건:
- 동일 기능에서 5회 이상 실패
- L3 접근법 전환 후에도 해결 불가
- 해당 기능이 핵심 게임플레이가 아닌 경우

범위 축소 불가 항목 (핵심 경로):
- 메인 게임 루프 (플레이어 이동, 기본 상호작용)
- 씬 전이 (메인→게임→게임오버)
- 컴파일 통과

## 중간 커밋 정책

```bash
# 검증 통과 후 커밋
git add -A && git commit -m "[auto] Phase N: description"
```

커밋 시점:
- Phase 1 scaffold 완료 후
- 각 태스크 구현 + compile-check 통과 후
- VQA 수정 완료 후
- 최종 폴리싱 완료 후

## Handoff (Iteration 종료 전 필수)

progress 파일의 `handoff` 필드를 반드시 업데이트:
```json
{
  "lastIteration": N,
  "completedInThisIteration": "이번에 완료한 작업",
  "nextSteps": "다음에 시작할 작업",
  "keyDecisions": ["설계 결정들"],
  "warnings": "주의사항"
}
```

## 강제 규칙 (절대 위반 금지)

1. **자동 진행**: Phase 간 사용자 확인 없이 자동 (Phase 0 승인 이후)
2. **단일 in_progress**: 동시에 하나의 태스크만
3. **완료 전 진행 금지**: 현재 태스크 완료 전 다음 시작 금지
4. **스킵 금지**: 태스크를 건너뛰지 않음
5. **게이트 필수**: Phase 전이 전 게이트 통과 필수
6. **상태 동기화**: 변경 시 progress JSON 즉시 업데이트
7. **질문 금지**: Phase 0 승인 외 사용자에게 질문하지 않음
8. **스크립트 우선**: 구조적 검사는 godot-gate.sh로

## 컨텍스트 관리

| 조건 | 대응 |
|------|------|
| 12턴 이상 | `/compact` |
| "prompt too long" | 즉시 `/compact` |
| Phase 전이 시 | `/compact` 후 다음 Phase 시작 |
