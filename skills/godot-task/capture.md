# 스크린샷/비디오 캡처 가이드

## 캡처 환경 (Linux)

Godot의 `--headless` 모드는 렌더링을 비활성화하므로 스크린샷이 불가합니다.
대신 **Xvfb (가상 디스플레이)** + 일반 모드로 실행합니다.

## capture.sh 사용법

### 스크린샷

```bash
bash ${CLAUDE_PLUGIN_ROOT}/tools/capture.sh screenshot \
  [--scene <scene_path>] \
  [--wait <seconds>] \
  [--output <filename>]
```

기본값:
- scene: `res://scenes/main.tscn`
- wait: 3초
- output: `screenshot_<timestamp>.png`

### 비디오

```bash
bash ${CLAUDE_PLUGIN_ROOT}/tools/capture.sh video \
  [--duration <seconds>] \
  [--output <filename>]
```

Godot의 `--write-movie` 옵션으로 AVI 캡처 후 ffmpeg으로 MP4 변환.

## 캡처 원리

1. `Xvfb :99 -screen 0 1280x720x24 &` — 가상 디스플레이 시작
2. `DISPLAY=:99 godot --path <project_dir> --write-movie output.avi` — 게임 실행 + 녹화
3. 지정 시간 후 `kill` → ffmpeg으로 AVI→MP4

## 주의사항

- Xvfb 필요: `sudo apt-get install xvfb`
- GPU 드라이버 필요 (클라우드 VM: T4/L4 권장)
- `--write-movie`는 Godot 4.0+ 지원
- 캡처 중 입력은 불가 → 자동 플레이 또는 데모 모드 필요
