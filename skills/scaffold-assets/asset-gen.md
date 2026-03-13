# 에셋 생성 도구 사용법

## asset_gen.py

Provider 추상화 레이어를 통해 이미지/3D/사운드/음악을 생성합니다.

### 이미지 생성

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/tools/asset_gen.py \
  --type image \
  --prompt "pixel art astronaut sprite, side view, transparent background" \
  --size "64x64" \
  --output "game/assets/sprites/player.png"
```

환경변수: `IMAGE_PROVIDER=gemini|flux|openai` (기본: gemini)

### 3D 모델 생성 (이미지→GLB)

```bash
# 먼저 참조 이미지 생성
python3 ${CLAUDE_PLUGIN_ROOT}/tools/asset_gen.py \
  --type image \
  --prompt "3D character reference, front view, clean design" \
  --output "ref_image.png"

# 이미지→GLB 변환
python3 ${CLAUDE_PLUGIN_ROOT}/tools/asset_gen.py \
  --type model3d \
  --input "ref_image.png" \
  --quality "medium" \
  --output "game/assets/models/character.glb"
```

환경변수: `MODEL3D_PROVIDER=tripo|meshy` (기본: tripo)

### 효과음 생성

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/tools/asset_gen.py \
  --type sound \
  --prompt "laser gun firing, sci-fi, 0.3 seconds" \
  --duration 0.3 \
  --output "game/assets/audio/sfx/laser.wav"
```

환경변수: `SOUND_PROVIDER=sfxengine|elevenlabs` (기본: sfxengine)

### 배경음악 생성

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/tools/asset_gen.py \
  --type music \
  --prompt "chiptune adventure game music, upbeat, 120 BPM" \
  --duration 30 \
  --genre "chiptune" \
  --output "game/assets/audio/bgm/main_theme.ogg"
```

환경변수: `MUSIC_PROVIDER=suno|stable` (기본: suno)

### 참조 이미지 생성

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/tools/asset_gen.py \
  --type reference \
  --prompt "2D space shooter game screenshot, pixel art, dark space background with colorful enemies" \
  --output "reference.png"
```

## rembg_matting.py — 배경 제거

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/tools/rembg_matting.py \
  --input "sprite_with_bg.png" \
  --output "sprite_clean.png"
```

## spritesheet.py — 스프라이트시트

### 생성 (개별 프레임 → 시트)
```bash
python3 ${CLAUDE_PLUGIN_ROOT}/tools/spritesheet.py pack \
  --frames "frame_*.png" \
  --cols 4 \
  --output "spritesheet.png"
```

### 슬라이싱 (시트 → 개별 프레임)
```bash
python3 ${CLAUDE_PLUGIN_ROOT}/tools/spritesheet.py slice \
  --input "spritesheet.png" \
  --cols 4 --rows 4 \
  --output-dir "frames/"
```

## 에셋 등록

생성된 에셋은 progress JSON에 자동 기록됩니다:
```json
{
  "type": "png",
  "path": "game/assets/sprites/player.png",
  "prompt": "...",
  "provider": "gemini",
  "cost": 0.035,
  "createdAt": "..."
}
```

budget도 자동 업데이트됩니다.

## 필요 API 키

| Provider | 환경변수 |
|----------|---------|
| Gemini | `GEMINI_API_KEY` |
| Flux | `FAL_API_KEY` |
| OpenAI | `OPENAI_API_KEY` |
| Tripo | `TRIPO_API_KEY` |
| Meshy | `MESHY_API_KEY` |
| SFX Engine | (불필요 — 무료) |
| ElevenLabs | `ELEVENLABS_API_KEY` |
| Suno | `SUNO_API_KEY` |
