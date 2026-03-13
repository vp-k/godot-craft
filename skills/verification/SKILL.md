---
name: verification
description: "Phase 5 — 최종 검증 + DoD 체크리스트 완료 + promise 선언"
---

# Phase 5: Verification

## 개요

모든 검증을 최종 실행하고, DoD 체크리스트를 완성한 후, promise를 선언합니다.

## 실행 순서

### Step 1: 전체 검증 실행

```bash
# 1. 컴파일 검증
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh compile-check

# 2. 에셋 정합성
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh asset-integrity

# 3. 씬 참조 정합성
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh scene-integrity

# 4. 예산 리포트
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh budget-report
```

### Step 2: DoD 체크리스트 업데이트

progress JSON의 `dod` 필드를 모두 업데이트합니다.
**각 항목은 직전 실행 결과를 evidence로 기록해야 합니다.**

```json
{
  "compileCheck": { "checked": true, "evidence": "compile-check exit 0, 0 errors" },
  "assetIntegrity": { "checked": true, "evidence": "all N assets validated" },
  "sceneIntegrity": { "checked": true, "evidence": "0 broken references" },
  "allTasksDone": { "checked": true, "evidence": "N/N tasks done" },
  "vqaPassed": { "checked": true, "evidence": "VQA round 2: pass, score 0.82" },
  "videoGenerated": { "checked": true, "evidence": "gameplay.mp4 (30s)" }
}
```

**금지**: 이전 실행 결과 재사용. 반드시 이 Phase에서 새로 실행.

### Step 3: 최종 상태 확인

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh status
```

모든 Phase가 completed인지, 모든 태스크가 done인지 확인.

### Step 4: Phase 5 완료

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh update-phase phase_5 completed
```

### Step 5: Promise 선언

**모든 조건 충족 시에만:**

```
<promise>MAKE_WITH_GODOT_COMPLETE</promise>
```

조건:
1. 모든 phases.status == "completed"
2. 모든 dod.*.checked == true
3. compile-check 직전 통과
4. 모든 tasks.status == "done"

하나라도 미충족이면 promise를 선언하지 않고, 미충족 항목을 해결합니다.

## 완료 조건

- [x] compile-check 통과 (직전 실행)
- [x] asset-integrity 통과 (직전 실행)
- [x] scene-integrity 통과 (직전 실행)
- [x] DoD 체크리스트 전체 checked + evidence
- [x] 모든 Phase completed
- [x] `<promise>MAKE_WITH_GODOT_COMPLETE</promise>` 선언
