# Visual QA 도구 가이드

## visual_qa.py

Gemini Flash를 사용하여 스크린샷의 시각적 품질을 평가합니다.

### 사용법

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/tools/visual_qa.py \
  --screenshots "screenshot_*.png" \
  --reference "reference.png" \
  --questions "질문1,질문2,질문3"
```

### 기본 질문 세트

1. 게임 화면이 시각적으로 올바르게 렌더링되는가?
2. UI 요소(점수, HP 등)가 올바른 위치에 표시되는가?
3. 스프라이트가 정상적으로 보이는가 (깨짐, 잘림 없음)?
4. 배경과 전경의 레이어가 올바른 순서인가?
5. 게임이 reference.png의 아트 스타일과 일관되는가?

### 출력 형식

```json
{
  "verdict": "pass|fail|acceptable",
  "score": 0.0-1.0,
  "issues": [
    {
      "severity": "high|medium|low",
      "description": "문제 설명",
      "location": "화면 위치 (선택)",
      "suggestion": "수정 제안"
    }
  ]
}
```

## screenshot_diff.py

SSIM(Structural Similarity Index)으로 reference와 스크린샷을 비교합니다.

### 사용법

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/tools/screenshot_diff.py \
  --reference "reference.png" \
  --screenshot "screenshot.png"
```

### 해석

| SSIM | 판정 |
|------|------|
| ≥ 0.85 | Good — 아트 스타일 일치 |
| 0.7-0.85 | Acceptable — 대체로 일치 |
| < 0.7 | Fail — 스타일 불일치 |

참고: reference.png는 개념도이므로, 정확한 픽셀 일치를 기대하지 않습니다.
SSIM은 전체적인 구조/색상/밝기 패턴의 유사도를 측정합니다.
