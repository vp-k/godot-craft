# Game Design Document

## Overview
- **Title**: [게임 제목]
- **Genre**: [장르]
- **Target Audience**: [타겟 플레이어]
- **Engine**: Godot 4
- **Type**: [2D / 3D]
- **Elevator Pitch**: [한 문장으로 게임 설명]

## Core Mechanics

### Primary Mechanic
[핵심 메커닉 설명 — 플레이어가 가장 많이 하는 행동]

### Secondary Mechanics
- [보조 메커닉 1]
- [보조 메커닉 2]

### Win Condition
[승리 조건]

### Lose Condition
[패배 조건]

## Controls

### Keyboard
| Action | Key | Godot Input Action |
|--------|-----|-------------------|
| Move Left | Arrow Left / A | `move_left` |
| Move Right | Arrow Right / D | `move_right` |
| Move Up | Arrow Up / W | `move_up` |
| Move Down | Arrow Down / S | `move_down` |
| Jump | Space | `jump` |
| Attack | Z / LMB | `attack` |
| Interact | E / Enter | `interact` |
| Pause | P / Escape | `pause` |

### Mouse
| Action | Input | Godot Input Action |
|--------|-------|-------------------|
| [액션] | LMB | `mouse_click` |

## Game States

```
MENU → PLAYING ↔ PAUSED
         ↓
      GAMEOVER → MENU (restart)
```

### State Descriptions
- **MENU**: 시작 화면. 게임 시작, 설정, 종료 옵션
- **PLAYING**: 게임플레이 진행 중
- **PAUSED**: 일시정지. 재개/메뉴 복귀 옵션
- **GAMEOVER**: 결과 화면. 점수, 재시작/메뉴 옵션

### Scene Transitions
| From | To | Trigger |
|------|----|---------|
| MENU | PLAYING | Start 버튼 / ui_accept |
| PLAYING | PAUSED | pause 액션 |
| PAUSED | PLAYING | pause 액션 |
| PLAYING | GAMEOVER | 패배 조건 충족 |
| GAMEOVER | MENU | restart / ui_accept |

## Visual Style

### Color Palette
- **Primary**: [색상 + hex]
- **Secondary**: [색상 + hex]
- **Accent**: [색상 + hex]
- **Background**: [색상 + hex]

### Art Style
[아트 스타일 설명 — 픽셀 아트, 미니멀리스트, 카툰 등]

### Entity Appearances
| Entity | Description | Size |
|--------|-------------|------|
| Player | [외형 설명] | [크기] |
| Enemy | [외형 설명] | [크기] |
| Collectible | [외형 설명] | [크기] |

### Reference
- `reference.png` 프롬프트: [이미지 생성 프롬프트]

## Difficulty Progression

### Level / Wave Structure
| Phase | Difficulty | New Elements |
|-------|-----------|-------------|
| 초반 | Easy | 기본 메커닉 학습 |
| 중반 | Medium | [새 요소 추가] |
| 후반 | Hard | [도전적 요소] |

### Scaling Parameters
- [속도/빈도/수량 등 난이도 조절 파라미터]

## Scoring System

### Points
| Action | Points |
|--------|--------|
| [점수 획득 행동] | [점수] |

### Multipliers / Combos
[콤보/멀티플라이어 시스템 설명, 없으면 "없음"]

### High Score
[최고 점수 저장 방식]

## Technical Notes (Godot 4)

### Physics
- **Physics Engine**: [Godot Physics / 커스텀]
- **Gravity**: [값]
- **Collision Layers**: [레이어 구성]

### Performance Targets
- **Target FPS**: 60
- **Max Entities**: [동시 엔티티 수 제한]

### Audio
- **BGM**: [배경음악 스타일]
- **SFX**: [효과음 목록]
