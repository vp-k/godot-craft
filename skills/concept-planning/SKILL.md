---
name: concept-planning
description: "Phase 0 — 게임 콘셉트 확장, 비주얼 타겟 생성, PLAN/STRUCTURE/ASSETS.md 작성, 사용자 승인"
---

# Phase 0: Concept & Planning

## 개요

사용자의 한 줄 요구사항을 완전한 게임 설계로 확장합니다.
이 Phase가 **사용자와 상호작용하는 유일한 시점**입니다.

## 실행 순서

### Step 1: 게임 콘셉트 확장

사용자 입력을 분석하여:
1. **장르** 판별 (platformer, shooter, puzzle, RPG, etc.)
2. **차원** 판별 (2D / 3D) — 명시 없으면 2D 기본
3. **핵심 메카닉** 정의 (이동, 공격, 수집, 퍼즐 등)
4. **게임 루프** 설계 (시작→플레이→승리/패배→재시작)
5. **콘셉트 문서** 작성 (2~3문단)

### Step 1.5: DESIGN.md 작성

`templates/game-design-template.md`를 기반으로 게임 디자인 문서를 작성합니다:

```
Read ${CLAUDE_PLUGIN_ROOT}/templates/game-design-template.md
```

8개 섹션을 채웁니다:
1. **Overview** — 제목, 장르, 타겟, 엘리베이터 피치
2. **Core Mechanics** — 주요/보조 메커닉, 승리/패배 조건
3. **Controls** — Godot Input Map 기준 키 매핑
4. **Game States** — 씬 전이 다이어그램 (MENU→PLAYING↔PAUSED→GAMEOVER)
5. **Visual Style** — 색상 팔레트, 아트 스타일, reference.png 프롬프트
6. **Difficulty Progression** — 난이도 곡선
7. **Scoring System** — 점수 체계
8. **Technical Notes** — Godot 4 물리 설정, 충돌 레이어 개요

DESIGN.md는 리뷰(Phase 4.5)에서 "원래 의도 vs 구현 결과" 비교 기준으로 활용됩니다.

**Quick 모드**: DESIGN.md를 간소화 — Overview + Core Mechanics + Controls만 작성.

### Step 2: 비주얼 타겟 프롬프트

게임의 시각적 목표를 정의하는 이미지 생성 프롬프트를 작성합니다:
- 아트 스타일 (픽셀아트, 카툰, 미니멀, 리얼리스틱 등)
- 색상 팔레트
- 분위기/톤

reference.png 생성:
```bash
python3 ${CLAUDE_PLUGIN_ROOT}/tools/asset_gen.py \
  --type reference \
  --prompt "<비주얼 타겟 프롬프트>" \
  --output reference.png
```

### Step 3: PLAN.md 작성

태스크 분해 + 의존성 DAG. 형식:

```markdown
# PLAN.md — <게임 이름>

## 개요
<게임 콘셉트 요약>

## 태스크

### T1: <태스크 제목>
- **설명**: <무엇을 구현하는지>
- **의존**: 없음
- **산출물**: <생성할 파일 목록>
- **완료 기준**: <검증 가능한 기준>

### T2: <태스크 제목>
- **설명**: ...
- **의존**: T1
- **산출물**: ...
- **완료 기준**: ...
```

태스크 분해 원칙:
- 각 태스크는 **1개의 기능 단위** (한 씬, 한 스크립트 그룹)
- 의존성은 **최소화** (병렬 실행 가능하게)
- 첫 태스크는 항상 **플레이어/메인 오브젝트** (가장 먼저 확인 가능)
- 마지막 태스크는 **메인 씬 통합 + 게임 루프**

### Step 4: STRUCTURE.md 작성

씬 트리, 스크립트 목록, 시그널 맵, 입력 액션, 충돌 레이어:

```markdown
# STRUCTURE.md — <게임 이름>

## 씬 트리

### main.tscn (Main)
- Node2D (Main)
  ├── Player (CharacterBody2D)
  ├── EnemySpawner (Node2D)
  ├── UI (CanvasLayer)
  │   ├── HUD
  │   └── PauseMenu
  └── GameManager (Node)

### player.tscn (Player)
- CharacterBody2D
  ├── Sprite2D
  ├── CollisionShape2D
  └── AnimationPlayer

## 스크립트 목록

| 스크립트 | extends | 역할 |
|---------|---------|------|
| main.gd | Node2D | 게임 루프 관리 |
| player.gd | CharacterBody2D | 플레이어 이동/공격 |

## 시그널 맵

| 발신 | 시그널 | 수신 | 용도 |
|------|--------|------|------|
| player.gd | health_changed(int) | hud.gd | HP 표시 업데이트 |
| player.gd | died | main.gd | 게임 오버 처리 |

## 입력 액션

| 액션 | 키 | 용도 |
|------|-----|------|
| move_left | A, Left | 왼쪽 이동 |
| move_right | D, Right | 오른쪽 이동 |
| jump | Space | 점프 |
| shoot | LMB | 사격 |

## 충돌 레이어

| Layer | 이름 | 용도 |
|-------|------|------|
| Layer 1 | player | 플레이어 |
| Layer 2 | enemy | 적 |
| Layer 3 | projectile | 투사체 |
| Layer 4 | environment | 환경/지형 |
```

### Step 5: ASSETS.md 작성

에셋 목록 + 예산 계획:

```markdown
# ASSETS.md — <게임 이름>

## 이미지

| 에셋 | 용도 | 크기 | 프롬프트 |
|------|------|------|----------|
| player.png | 플레이어 스프라이트 | 64x64 | <생성 프롬프트> |
| enemy_01.png | 기본 적 | 64x64 | <생성 프롬프트> |

## 사운드 (SFX)

| 에셋 | 용도 | 길이 | 프롬프트 |
|------|------|------|----------|
| jump.wav | 점프 효과음 | 0.3s | <프롬프트> |
| explosion.wav | 폭발 효과음 | 0.5s | <프롬프트> |

## 음악 (BGM)

| 에셋 | 용도 | 길이 | 프롬프트 |
|------|------|------|----------|
| main_theme.ogg | 메인 BGM | 30s | <프롬프트> |

## 3D 모델 (3D 게임만)

| 에셋 | 용도 | 폴리곤 | 프롬프트 |
|------|------|--------|----------|

## 예산 요약

| 카테고리 | 수량 | 예상 비용 |
|----------|------|-----------|
| 이미지 | N | $X.XX |
| 사운드 | N | $0.00 (무료) |
| 음악 | N | $X.XX |
| 3D 모델 | N | $X.XX |
| **합계** | | **$X.XX** |
```

### Step 6: 사용자 승인

**유일한 상호작용 시점.**

사용자에게 보여줄 것:
1. 게임 콘셉트 요약
2. reference.png (생성된 경우)
3. 태스크 수와 주요 마일스톤
4. 예상 에셋 비용
5. 승인 요청

### Step 7: Progress 초기화 + 게이트

승인 후:

```bash
# progress 초기화
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh init "<game_name>" "<requirement>" "<2d|3d>"

# PLAN.md의 태스크를 progress JSON에 로드
# (LLM이 jq로 직접 수행 — PLAN.md 파싱 → tasks 배열 구성)

# Phase 상태 업데이트
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh update-phase phase_0 completed

# 게이트 통과
bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh plan-gate
```

## 태스크 JSON 형식

PLAN.md의 태스크를 다음 형식으로 progress JSON에 로드:

```json
{
  "id": "T1",
  "title": "플레이어 캐릭터",
  "description": "플레이어 씬 + 이동 스크립트",
  "deps": [],
  "status": "pending",
  "outputs": ["scenes/player.tscn", "scripts/player.gd"],
  "createdAt": "2026-03-13T...",
  "updatedAt": ""
}
```

의존성이 없는 태스크는 자동으로 "ready" 상태로 전환됩니다.

## 완료 조건

- [x] DESIGN.md 작성 완료
- [x] PLAN.md 작성 완료
- [x] STRUCTURE.md 작성 완료
- [x] ASSETS.md 작성 완료
- [x] 사용자 승인 획득
- [x] progress JSON 초기화 + 태스크 로드
- [x] plan-gate 통과
