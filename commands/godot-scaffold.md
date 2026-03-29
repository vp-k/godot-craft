---
description: "Godot 프로젝트 스캐폴딩 + 에셋 생성. Phase 1만 단독 실행."
argument-hint: "[프로젝트 경로 (기본: 자동 탐지)]"
---

# /godot-scaffold — 스캐폴드 & 에셋

Phase 1(Scaffold & Assets)만 단독 실행합니다.
PLAN.md, STRUCTURE.md, ASSETS.md가 이미 존재해야 합니다.

## 사용법
```
/godot-scaffold
/godot-scaffold my-space-game
```

## 전제 조건
- Phase 0 completed (PLAN.md + STRUCTURE.md + ASSETS.md 존재)

## 동작

1. 공통 규칙 로드
   ```
   Read ${CLAUDE_PLUGIN_ROOT}/rules/shared-rules.md
   ```

2. Progress 확인
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/godot-gate.sh status
   ```

3. Phase 1 스킬 로드 및 실행
   ```
   Read ${CLAUDE_PLUGIN_ROOT}/skills/scaffold-assets/SKILL.md
   ```

4. 결과물:
   - `project.godot` + 디렉토리 구조
   - 스크립트 스텁 (`.gd`)
   - 씬 파일 (`.tscn`)
   - 생성된 에셋 (이미지, 사운드 등)
