---
name: visual-qa-fix
description: "Phase 3 — 스크린샷 기반 VQA 검수 + SSIM 비교 + 수정 (최대 3라운드)"
---

# Phase 3: Visual QA & Fix

## 개요

게임 실행 스크린샷을 캡처하고, VQA(Visual Question Answering)로 시각적 품질을 검수합니다.
reference.png 대비 SSIM(구조적 유사도)도 측정합니다. 최대 3라운드 반복.

## VQA 루프

```
반복 (최대 3회) {
    1. 스크린샷 캡처 (여러 장면)
    2. VQA 실행 (Gemini Flash)
    3. SSIM 비교 (reference.png vs 스크린샷)
    4. 리포트 분석 → 수정 계획
    5. 수정 실행
    6. compile-check
}
```

### Step 1: 스크린샷 캡처

여러 게임 상태의 스크린샷을 캡처합니다:

```bash
# 메인 화면
bash ${CLAUDE_PLUGIN_ROOT}/tools/capture.sh screenshot --scene main --wait 2

# 게임플레이 (시간 경과)
bash ${CLAUDE_PLUGIN_ROOT}/tools/capture.sh screenshot --scene main --wait 5

# 특정 상태 (게임 오버, 메뉴 등)
bash ${CLAUDE_PLUGIN_ROOT}/tools/capture.sh screenshot --scene main --wait 10
```

### Step 2: VQA 실행

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/tools/visual_qa.py \
  --screenshots "screenshot_*.png" \
  --reference "reference.png" \
  --questions "게임이 시각적으로 올바르게 보이는가?,UI 요소가 올바른 위치에 있는가?,스프라이트가 정상적으로 렌더링되는가?"
```

VQA 결과: JSON 리포트
```json
{
  "verdict": "fail|pass|acceptable",
  "issues": [
    {"severity": "high|medium|low", "description": "...", "suggestion": "..."}
  ],
  "score": 0.75
}
```

### Step 3: SSIM 비교

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/tools/screenshot_diff.py \
  --reference "reference.png" \
  --screenshot "screenshot_main.png"
```

SSIM ≥ 0.7 → acceptable, SSIM ≥ 0.85 → good

### Step 4: 리포트 분석

VQA 리포트의 issues를 분석하여 수정 계획 수립:
- **high severity**: 반드시 수정
- **medium severity**: 가능하면 수정
- **low severity**: 시간 허용 시 수정

### Step 5: 수정 실행

godot-task 스킬 패턴으로 수정합니다.

### Step 6: 라운드 기록

```bash
# progress에 VQA 라운드 기록 (jq로 직접)
# vqa.rounds에 {round, verdict, score, issues, fixes} 추가
# vqa.currentRound 증가
```

### Step 7: VQA 게이트

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh vqa-gate
```

## 완료 조건

- [x] 최소 1라운드 VQA 실행
- [x] verdict가 pass 또는 acceptable
- [x] vqa-gate 통과
