# 씬 생성 가이드 (.tscn)

## .tscn 파일 구조

```
[gd_scene load_steps=<N> format=3]       ← 헤더 (필수)

[ext_resource ...]                        ← 외부 리소스 참조
[sub_resource ...]                        ← 인라인 서브리소스

[node ...]                                ← 노드 트리
[connection ...]                          ← 시그널 연결
```

### load_steps 계산
`load_steps` = ext_resource 수 + sub_resource 수 + 1

## 예제: 2D 플레이어 씬

```
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/player.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/sprites/player.png" id="2"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_1"]
size = Vector2(32, 64)

[node name="Player" type="CharacterBody2D"]
script = ExtResource("1")
speed = 200.0

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_1")
```

## 예제: 메인 씬 (인스턴스 사용)

```
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/main.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/player.tscn" id="2"]
[ext_resource type="PackedScene" path="res://scenes/hud.tscn" id="3"]

[node name="Main" type="Node2D"]
script = ExtResource("1")

[node name="Player" parent="." instance=ExtResource("2")]
position = Vector2(640, 360)

[node name="UI" type="CanvasLayer" parent="."]

[node name="HUD" parent="UI" instance=ExtResource("3")]

[connection signal="health_changed" from="Player" to="UI/HUD" method="_on_health_changed"]
[connection signal="died" from="Player" to="." method="_on_player_died"]
```

## 노드 속성

### parent 규칙
- 루트 노드: `parent` 없음
- 직접 자식: `parent="."`
- 깊은 자식: `parent="Parent/Child"`

### 일반 프로퍼티
```
position = Vector2(100, 200)
rotation = 1.5708                    # 라디안
scale = Vector2(2, 2)
visible = false
z_index = 1
modulate = Color(1, 0, 0, 1)        # RGBA
```

### CollisionShape2D
```
[sub_resource type="CircleShape2D" id="Circle_1"]
radius = 16.0

[sub_resource type="RectangleShape2D" id="Rect_1"]
size = Vector2(32, 64)

[sub_resource type="CapsuleShape2D" id="Capsule_1"]
radius = 16.0
height = 64.0
```

### Area2D (트리거)
```
[node name="Hitbox" type="Area2D" parent="."]
collision_layer = 4
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="Hitbox"]
shape = SubResource("Circle_1")
```

### Sprite2D
```
[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2")
hframes = 4                          # 스프라이트시트 가로 프레임
vframes = 2                          # 스프라이트시트 세로 프레임
frame = 0
centered = true
offset = Vector2(0, -16)
```

### AudioStreamPlayer2D
```
[ext_resource type="AudioStream" path="res://assets/audio/sfx/jump.wav" id="5"]

[node name="JumpSound" type="AudioStreamPlayer2D" parent="."]
stream = ExtResource("5")
volume_db = -5.0
max_distance = 500.0
```

### Timer
```
[node name="SpawnTimer" type="Timer" parent="."]
wait_time = 2.0
one_shot = false
autostart = true

[connection signal="timeout" from="SpawnTimer" to="." method="_on_spawn_timer_timeout"]
```

### Camera2D
```
[node name="Camera2D" type="Camera2D" parent="."]
zoom = Vector2(2, 2)
position_smoothing_enabled = true
position_smoothing_speed = 5.0
limit_left = 0
limit_top = 0
```

## 3D 씬 예제

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/player_3d.gd" id="1"]

[sub_resource type="BoxShape3D" id="Box_1"]
size = Vector3(1, 2, 1)

[sub_resource type="BoxMesh" id="BoxMesh_1"]
size = Vector3(1, 2, 1)

[node name="Player" type="CharacterBody3D"]
script = ExtResource("1")

[node name="MeshInstance3D" type="MeshInstance3D" parent="."]
mesh = SubResource("BoxMesh_1")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
shape = SubResource("Box_1")
```

## UI 씬 예제

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/hud.gd" id="1"]

[node name="HUD" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="ScoreLabel" type="Label" parent="."]
layout_mode = 1
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -200.0
offset_bottom = 40.0
text = "Score: 0"
horizontal_alignment = 2

[node name="HealthBar" type="ProgressBar" parent="."]
layout_mode = 1
anchors_preset = 0
offset_right = 200.0
offset_bottom = 30.0
value = 100.0
```
