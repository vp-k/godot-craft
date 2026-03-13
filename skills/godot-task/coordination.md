# 씬 간 조정 (Coordination)

## 씬 통합 원칙

### 1. 시그널로 통신 (권장)
```gdscript
# player.gd — 발신
signal health_changed(value: int)
health_changed.emit(health)

# main.gd — 중계
func _ready():
    $Player.health_changed.connect($UI/HUD.update_health)
```

### 2. 그룹으로 브로드캐스트
```gdscript
# 적에게 대미지 (main.gd)
get_tree().call_group("enemies", "take_damage", 50)
```

### 3. Autoload (글로벌 상태)
project.godot에 등록:
```ini
[autoload]
GameManager="*res://scripts/game_manager.gd"
```
어디서든 접근:
```gdscript
GameManager.add_score(100)
```

## 충돌 레이어 조정

STRUCTURE.md의 충돌 레이어 기반으로:
```gdscript
# Layer: 비트마스크 (1-based)
# Layer 1 (player):     collision_layer = 1
# Layer 2 (enemy):      collision_layer = 2
# Layer 3 (projectile): collision_layer = 4
# Layer 4 (environment): collision_layer = 8

# 플레이어: Layer 1에 존재, Layer 2+4 감지
# collision_layer = 1, collision_mask = 6

# 적: Layer 2에 존재, Layer 1+4 감지
# collision_layer = 2, collision_mask = 5
```

## 씬 전환 패턴

```gdscript
# 즉시 전환
get_tree().change_scene_to_file("res://scenes/game_over.tscn")

# 데이터 전달 (Autoload 경유)
GameManager.final_score = score
get_tree().change_scene_to_file("res://scenes/result.tscn")
```

## 인스턴스 동적 생성

```gdscript
var bullet_scene = preload("res://scenes/bullet.tscn")

func shoot():
    var bullet = bullet_scene.instantiate()
    bullet.position = $Muzzle.global_position
    bullet.direction = (get_global_mouse_position() - global_position).normalized()
    get_parent().add_child(bullet)  # 부모에 추가 (플레이어 자식X)
```
