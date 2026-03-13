# 프로젝트 스캐폴딩 상세 가이드

## 디렉토리 구조

```
<game_name>/
├── project.godot           # 엔진 설정
├── .gitignore
├── icon.svg
├── scenes/                 # .tscn 씬 파일
│   ├── main.tscn
│   ├── player.tscn
│   └── ...
├── scripts/                # .gd 스크립트
│   ├── main.gd
│   ├── player.gd
│   └── ...
├── assets/
│   ├── sprites/            # 2D 이미지
│   ├── models/             # 3D GLB
│   ├── audio/
│   │   ├── sfx/            # 효과음
│   │   └── bgm/            # 배경 음악
│   ├── fonts/              # 폰트
│   └── ui/                 # UI 이미지
├── resources/              # .tres 리소스
│   └── default_theme.tres
├── translation/            # i18n (선택)
│   └── messages.csv
└── addons/                 # 플러그인 (선택)
```

## project.godot 주요 설정

### 2D 게임
- `renderer/rendering_method = "gl_compatibility"` — 호환성 렌더러
- `window/size/viewport_width = 1280`
- `window/size/viewport_height = 720`
- `window/stretch/mode = "canvas_items"` — 해상도 독립적

### 3D 게임
- `renderer/rendering_method = "forward_plus"` — Forward+ 렌더러
- 나머지 동일

### 입력 액션

STRUCTURE.md의 입력 액션을 project.godot에 등록해야 합니다.

**방법 1**: project.godot에 직접 작성 (복잡하므로 비권장)

**방법 2**: 오토로드 스크립트에서 프로그래매틱하게 등록 (권장)

```gdscript
# input_setup.gd (autoload)
extends Node

func _ready() -> void:
    _register_action("move_left", [KEY_A, KEY_LEFT])
    _register_action("move_right", [KEY_D, KEY_RIGHT])
    _register_action("move_up", [KEY_W, KEY_UP])
    _register_action("move_down", [KEY_S, KEY_DOWN])
    _register_action("jump", [KEY_SPACE])
    _register_action("shoot", [])  # 마우스 버튼은 별도

func _register_action(action_name: String, keys: Array) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)
        for key in keys:
            var event = InputEventKey.new()
            event.physical_keycode = key
            InputMap.action_add_event(action_name, event)
```

이 경우 project.godot에 autoload 추가:
```ini
[autoload]
InputSetup="*res://scripts/input_setup.gd"
```
