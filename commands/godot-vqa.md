---
description: "스크린샷 기반 VQA(Visual QA) 재실행. Phase 3만 단독 실행."
argument-hint: "[프로젝트 경로 (기본: 자동 탐지)]"
---

# /godot-vqa — Visual QA 재실행

Phase 3(Visual QA & Fix)만 단독 실행합니다.
스크린샷을 캡처하고, Gemini Flash로 시각 분석하고, SSIM 비교 후 수정합니다.

## 사용법
```
/godot-vqa
/godot-vqa my-space-game
```

## 전제 조건
- Phase 2 completed (또는 일부 태스크 구현 완료)
- compile-check 통과

## 동작

1. 공통 규칙 로드
   ```
   Read ${CLAUDE_PLUGIN_ROOT}/rules/shared-rules.md
   ```

2. VQA 스킬 로드 및 실행
   ```
   Read ${CLAUDE_PLUGIN_ROOT}/skills/visual-qa-fix/SKILL.md
   ```

3. VQA 루프 (최대 3회):
   - 스크린샷 캡처 (여러 장면)
   - VQA 실행 (Gemini Flash)
   - SSIM 비교 (reference.png 대비)
   - 리포트 분석 → 수정 → compile-check → 재캡처

## 필수 환경변수
- `GEMINI_API_KEY` — Gemini Flash VQA용
