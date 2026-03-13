---
name: polish-present
description: "Phase 4 — 디버그 코드 제거, 코드 정리, 게임플레이 비디오 캡처"
---

# Phase 4: Polish & Presentation

## 개요

최종 코드 정리, 디버그 코드 제거, 게임플레이 비디오 캡처.

## 실행 순서

### Step 1: 디버그 코드 탐색

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh find-debug-code
```

발견된 `print()`, `breakpoint`, 불필요한 `assert()` 등을 제거합니다.

### Step 2: 코드 폴리싱

- 미사용 변수/함수 제거
- 시그널 연결 정리
- `@export` 값 최종 조정
- 물리 파라미터 미세 튜닝 (속도, 중력, 대미지 등)

### Step 3: 프레젠테이션 시나리오 설계

게임플레이 비디오에 담을 장면:
1. 게임 시작 (타이틀/메뉴)
2. 핵심 게임플레이 (이동, 상호작용)
3. 주요 이벤트 (적 출현, 보스, 아이템 획득 등)
4. 게임 결말 (승리/패배)

### Step 4: 게임플레이 비디오 캡처

```bash
# Xvfb + Godot --write-movie
bash ${CLAUDE_PLUGIN_ROOT}/tools/capture.sh video --duration 30
```

### Step 5: 비디오 변환 (AVI → MP4)

```bash
ffmpeg -i gameplay.avi -c:v libx264 -crf 23 -c:a aac gameplay.mp4
```

### Step 6: Final 게이트

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh final-gate
```

## 완료 조건

- [x] 디버그 코드 제거
- [x] 코드 정리
- [x] 게임플레이 비디오 생성
- [x] final-gate 통과
