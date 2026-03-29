---
description: "텍스트 한 줄로 Godot 4 게임을 자율 생성. 6-Phase 파이프라인으로 콘셉트→스캐폴드→구현→VQA→폴리싱→검증 전 과정 자동화"
argument-hint: <게임 설명 (자연어, 예: "우주 슈팅 게임 만들어줘")> [--quick]
---

# Make with Godot — 메인 오케스트레이터

**역할**: 6-Phase 파이프라인 오케스트레이터. Phase 전이, Ralph Loop, Progress 관리의 유일한 소유자.
**핵심 원칙**: Phase 0에서만 사용자 승인, 이후 완전 자동.

## 인수

- `$ARGUMENTS`: 게임 설명 (자연어)
- `--quick`: Quick 모드 활성화 (선택)

## 모드 판별

### Quick 모드 활성화 조건
- `--quick` 플래그가 인수에 포함
- 사용자가 명시적으로 요청: "빠르게", "quick으로", "간단하게 만들어줘"
- **주의**: 단순히 "간단한 게임"이라는 설명만으로는 활성화하지 않음

### Quick 모드 (3-Phase)
간단한 게임(Pong, Snake, 브레이크아웃 등)에 적합한 축약 파이프라인.
에셋 생성, VQA, 비디오 캡처, 다관점 리뷰를 생략합니다.

1. **Quick Phase 0: 간소화 계획**
   - PLAN.md만 작성 (STRUCTURE.md, ASSETS.md 최소화)
   - 에셋은 프로시저럴(ColorRect, 기본 도형)만 사용
   - 사용자 승인

2. **Quick Phase 1+2: 스캐폴드 + 구현**
   - 프로젝트 구조 생성 (AI 에셋 생성 생략)
   - 태스크를 DAG 대신 순차 구현
   - 매 태스크 후 compile-check + 기본 테스트
   - 게이트 없이 자동 진행

3. **Quick Phase 5: 검증**
   - compile-check + 인터랙티브 배치 테스트
   - VQA, 폴리싱, 비디오 캡처 스킵
   - 전체 시나리오 PASS → 완료

Quick 모드에서 progress JSON의 `mode` 필드를 `"quick"`으로 설정합니다.

### 기본 모드 (6-Phase + Review)
아래 6-Phase 파이프라인을 실행합니다.

## 아키텍처: 오케스트레이터 + Phase 스킬

```
이 파일 (오케스트레이터) — Ralph Loop, Phase 전이, Progress 관리 소유 (유일)
    ↓ Read로 Phase별 스킬 로드
    ├── skills/concept-planning/SKILL.md    (Phase 0)
    ├── skills/scaffold-assets/SKILL.md     (Phase 1)
    ├── skills/implementation/SKILL.md      (Phase 2)
    ├── skills/visual-qa-fix/SKILL.md       (Phase 3)
    ├── skills/polish-present/SKILL.md      (Phase 4)
    └── skills/verification/SKILL.md        (Phase 5)
```

**단일 소스 원칙**: 규칙은 `shared-rules.md`와 각 스킬 파일에만 존재. 이 파일은 흐름만 정의.

## 6-Phase 파이프라인

```
Phase 0: Concept & Planning ─── 사용자 승인 (유일한 상호작용)
    ↓ [plan-gate]
Phase 1: Scaffold & Assets ─── 프로젝트 구조 + 에셋 생성
    ↓ [scaffold-gate]
Phase 2: Implementation ─── 태스크별 구현
    ↓ [impl-gate]
Phase 3: Visual QA & Fix ─── 스크린샷 기반 시각 검수
    ↓ [vqa-gate]
Phase 4: Polish & Presentation ─── 최종 폴리싱 + 비디오
    ↓ [final-gate]
Phase 5: Verification ─── 최종 검증 + 완료 선언
    ↓
<promise>MAKE_WITH_GODOT_COMPLETE</promise>
```

## 실행 순서

### 0. 공통 규칙 로드 (최우선)

```
Read ${CLAUDE_PLUGIN_ROOT}/rules/shared-rules.md
```

### 1. Ralph Loop 자동 설정

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh init-ralph "MAKE_WITH_GODOT_COMPLETE" ".claude-godot-progress.json"
```

### 2. 복구 감지

`.claude-godot-progress.json`이 이미 존재하면:
1. `bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh status`로 현재 상태 확인
2. `handoff` 필드 읽기 → 중단된 지점 파악
3. 해당 Phase 스킬을 Read로 로드하여 재개

### 3. Phase 0: Concept & Planning

```
Read ${CLAUDE_PLUGIN_ROOT}/skills/concept-planning/SKILL.md
```

이 Phase에서만 사용자와 상호작용합니다:
1. 게임 콘셉트 확장 + 비주얼 타겟 생성
2. PLAN.md + STRUCTURE.md + ASSETS.md 작성
3. **사용자 승인 요청** (유일한 상호작용)
4. 승인 후 progress 초기화 + plan-gate 통과

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh init "<game_name>" "$ARGUMENTS" "<2d|3d>"
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh update-phase phase_0 in_progress
# ... Phase 0 실행 ...
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh plan-gate
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh update-phase phase_0 completed
```

### 4. Phase 1: Scaffold & Assets

```
Read ${CLAUDE_PLUGIN_ROOT}/skills/scaffold-assets/SKILL.md
```

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh update-phase phase_1 in_progress
# ... Phase 1 실행 ...
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh scaffold-gate
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh update-phase phase_1 completed
```

### 5. Phase 2: Implementation

```
Read ${CLAUDE_PLUGIN_ROOT}/skills/implementation/SKILL.md
```

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh update-phase phase_2 in_progress
# 태스크 루프 (implementation/SKILL.md가 관리)
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh impl-gate
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh update-phase phase_2 completed
```

### 6. Phase 3: Visual QA & Fix

```
Read ${CLAUDE_PLUGIN_ROOT}/skills/visual-qa-fix/SKILL.md
```

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh update-phase phase_3 in_progress
# ... VQA 루프 (최대 3회) ...
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh vqa-gate
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh update-phase phase_3 completed
```

### 7. Phase 4: Polish & Presentation

```
Read ${CLAUDE_PLUGIN_ROOT}/skills/polish-present/SKILL.md
```

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh update-phase phase_4 in_progress
# ... 폴리싱 + 비디오 ...
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh final-gate
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh update-phase phase_4 completed
```

### 7.5. Phase 4.5: Multi-Perspective Review

```
Read ${CLAUDE_PLUGIN_ROOT}/skills/godot-review/SKILL.md
```

3인 병렬 리뷰 실행:
1. 인터랙티브 테스트로 스크린샷 확보
2. 3개 Agent 동시 호출 (UX 디자이너, 게임 디자이너, 기술 리뷰어)
3. 결과 통합 → `reviews/review-dashboard.md`
4. Priority Fixes Top 3 → Phase 5 전에 수정 실행

### 8. Phase 5: Verification

```
Read ${CLAUDE_PLUGIN_ROOT}/skills/verification/SKILL.md
```

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh update-phase phase_5 in_progress
# ... 최종 검증 ...
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh update-phase phase_5 completed
```

## Ralph Loop 완료 조건

**모든 조건을 충족해야만** `<promise>MAKE_WITH_GODOT_COMPLETE</promise>` 출력:

1. `.claude-godot-progress.json`의 모든 phases status가 `completed`
2. `.claude-godot-progress.json`의 `dod` 체크리스트가 모두 `checked: true`
3. `godot-gate.sh compile-check` 통과
4. 위 조건을 **직전에 확인**한 결과여야 함 (캐시된 결과 사용 금지)

## Handoff (Iteration 종료 전 필수)

매 iteration 종료 시 progress 파일의 handoff 업데이트:
```json
{
  "lastIteration": N,
  "completedInThisIteration": "완료한 작업 요약",
  "nextSteps": "다음 iteration에서 시작할 작업",
  "keyDecisions": ["이번에 내린 설계 결정"],
  "warnings": "주의사항"
}
```

## 강제 규칙

1. **자동 진행**: Phase 0 승인 이후, Phase 간 사용자 확인 없이 자동 진행
2. **단일 in_progress**: 동시에 하나의 태스크/Phase만
3. **게이트 필수**: Phase 전이 전 반드시 게이트 통과
4. **스킵 금지**: 어떤 Phase도 건너뛰지 않음
5. **중간 종료 금지**: 모든 Phase completed까지 종료하지 않음
6. **상태 동기화**: 변경 시 progress JSON 즉시 업데이트
7. **스크립트 우선**: 구조적/기계적 검사는 godot-gate.sh로
8. **handoff 필수**: 매 iteration 종료 시 업데이트
9. **질문 금지**: Phase 0과 L5 에스컬레이션 외 사용자에게 질문하지 않음
10. **Phase별 스킬 Read**: 각 Phase 시작 시 해당 스킬을 Read로 로드 (오케스트레이터에 로직 중복 금지)
