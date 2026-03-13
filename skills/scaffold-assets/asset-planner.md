# 에셋 계획 전략

## 에셋 우선순위

1. **플레이어 스프라이트** — 가장 먼저, 아트 스타일 기준점
2. **적/NPC 스프라이트** — 플레이어와 동일 스타일
3. **배경/환경** — 게임 분위기 결정
4. **UI 요소** — HUD, 버튼, 메뉴
5. **SFX** — 핵심 상호작용 (점프, 공격, 피격)
6. **BGM** — 메인 테마

## 이미지 프롬프트 작성 원칙

### 스프라이트 (캐릭터/오브젝트)
```
"[아트스타일] [대상] sprite, [방향], [포즈], on transparent background,
[크기]px, game asset, clean edges, [추가 디테일]"
```

예시:
```
"pixel art astronaut character sprite, side view, idle pose, on transparent background,
64x64px, game asset, clean edges, space suit with blue visor"
```

### 배경
```
"[아트스타일] [장면] background, [구도], [시간/분위기],
seamless tileable, 1280x720px, game background"
```

### 스프라이트시트
```
"[아트스타일] [대상] sprite sheet, [행x열] grid, [액션 시퀀스],
on transparent background, each frame [크기]px, game asset"
```

예시:
```
"pixel art knight sprite sheet, 4x4 grid, walk cycle (4 frames) top row,
idle (4 frames) second row, attack (4 frames) third row, death (4 frames) bottom row,
on transparent background, each frame 64x64px"
```

## SFX 프롬프트 작성

```
"[효과 유형]: [구체적 설명], [길이], [분위기]"
```

예시:
- `"jump sound effect: bouncy spring jump, 0.3 seconds, cartoony"`
- `"explosion: large fiery explosion, 1 second, dramatic"`
- `"coin pickup: bright cheerful ding, 0.2 seconds, satisfying"`

## BGM 프롬프트 작성

```
"[장르] [분위기] game music, [템포], [악기], [용도]"
```

예시:
- `"chiptune upbeat adventure game music, 120 BPM, 8-bit synthesizers, main gameplay loop"`
- `"orchestral epic boss battle music, 140 BPM, strings and brass, intense combat"`

## 예산 관리

| Provider | 단가 | 비고 |
|----------|------|------|
| Gemini 이미지 | ~$0.035/장 | 기본 |
| SFX Engine | 무료 | 무제한 |
| Suno BGM | ~$0.004/곡 | $10/월 2500크레딧 |
| Tripo 3D | ~$0.10-0.25/모델 | 3D만 |

### 예산 절약 팁
- 스프라이트시트 1장 > 개별 프레임 N장
- 유사한 적은 색상 변형(modulate)으로 재활용
- BGM은 1~2곡으로 충분 (메인 + 보스/게임오버)
- SFX는 무료 Provider 사용
