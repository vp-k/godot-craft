---
name: godot-review
description: "완성된 Godot 게임을 UX 디자이너, 게임 디자이너, 기술 리뷰어(Godot 전문) 3관점으로 병렬 평가한다."
---

# Godot Review — 다관점 리뷰

완성된 Godot 게임을 3개의 전문가 페르소나가 독립적으로 평가합니다.
게임 코드를 수정하지 않고 평가만 수행합니다.

## 필수 참조
- **리뷰 페르소나**: `rules/review-personas-godot.md`
- **리뷰 템플릿**: `templates/review-template.md`
- **테스팅 규칙**: `rules/testing-rules-godot.md`

## 입력
- 프로젝트의 GDScript 파일들 (`.gd`)
- 씬 파일들 (`.tscn`)
- 스크린샷 (`test_output/shot-*.png`)
- 테스트 결과 (`test_output/batch-summary.json`, `test_output/state-*.json`)
- DESIGN.md (있으면 — 게임 설계 의도 참조)

## 출력
- `reviews/review-dashboard.md` — 통합 리뷰 대시보드

## 프로세스

### 1. 사전 준비

1. 프로젝트 디렉토리 확인 (progress JSON에서 `gameName` 읽기)
2. 인터랙티브 테스트로 최신 스크린샷 확보:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-test-runner.sh \
     --inject-autoloads \
     --scenarios idle,start-game,basic-movement \
     --output-dir test_output
   ```
3. 스크린샷을 Read 도구로 열어 게임 상태 확인
4. GDScript 파일 목록 수집 (Glob `**/*.gd`)
5. 씬 파일 목록 수집 (Glob `**/*.tscn`)

### 2. 3인 병렬 리뷰

Agent 도구를 **단일 메시지에서 3개 동시 호출**하여 병렬 실행:

**Agent 1 — UX 디자이너 (김지연)**
프롬프트에 포함할 내용:
- `rules/review-personas-godot.md`의 UX 디자이너 섹션
- 스크린샷 파일 경로 목록 (Read로 열어서 시각적 분석)
- 테스트 결과 (`test_output/batch-summary.json`)
- 게임 상태 JSON (`test_output/state-*.json`)
- DESIGN.md (있으면)
- 평가 항목: Control Responsiveness, Visual Clarity, Onboarding, Feedback, Accessibility
- 각 항목 1~5점 + 이슈 목록 (severity: high/medium/low) + 요약 2~3문장 출력 요청

**Agent 2 — 게임 디자이너 (이준호)**
프롬프트에 포함할 내용:
- `rules/review-personas-godot.md`의 게임 디자이너 섹션
- 스크린샷 파일 경로 목록
- GDScript 주요 파일 (게임 로직, 메커닉 관련)
- DESIGN.md (있으면 — 설계 의도와 구현 비교)
- 평가 항목: Fun Factor, Game Balance, Difficulty Curve, Replayability, Juice
- 각 항목 1~5점 + 이슈 목록 + 요약 2~3문장 출력 요청

**Agent 3 — 기술 리뷰어 (박민준)**
프롬프트에 포함할 내용:
- `rules/review-personas-godot.md`의 기술 리뷰어 섹션
- 모든 GDScript 파일 (`**/*.gd`)
- 모든 씬 파일 (`**/*.tscn`)
- 테스트 에러 로그 (`test_output/errors-*.json`, 있으면)
- 평가 항목: GDScript Performance, Code Quality, Error Handling, Scene Structure, Node Lifecycle
- 각 항목 1~5점 + 이슈 목록 + 요약 2~3문장 출력 요청

### 3. 결과 통합

3개 Agent 결과를 수집한 후:
1. `templates/review-template.md`를 기반으로 `reviews/review-dashboard.md` 생성
2. 각 페르소나의 점수, 이슈, 요약을 해당 섹션에 채움
3. Overall Verdict 테이블 작성 (평균 점수 + Ship Ready 여부)
4. Priority Fixes Top 3 선정 (3인의 이슈를 종합하여 가장 심각한 3개)

### 4. 사용자에게 보고

리뷰 대시보드의 핵심 내용을 요약하여 보고:
- 각 관점의 평균 점수
- Ship Ready 여부
- Priority Fixes Top 3
- 상세 내용은 `reviews/review-dashboard.md` 참조 안내

## 파이프라인 통합

`make-game.md`에서 Phase 4(Polish) 완료 후, Phase 5(Verification) 전에 실행:
```
Phase 4: Polish & Presentation
    ↓
Phase 4.5: Multi-Perspective Review (이 스킬)
    ↓ Priority Fixes Top 3 수정
Phase 5: Verification
```

## 완료 조건

- [x] 3개 Agent 병렬 실행 완료
- [x] reviews/review-dashboard.md 생성
- [x] Overall Verdict 및 Priority Fixes Top 3 확정
