class_name LinearBullet
extends BulletBase
## 직선 이동 탄막 — 원형(소/중/대)을 이 클래스 하나로 커버.
## circle_size 로 반경/속도/색상 프리셋이 결정된다.

var circle_size: int = GameConfig.CircleSize.SMALL
var _radius := 6.0
var _color := Color.WHITE


# 발사: 시작점/방향/속도배수. BulletSpawner.fire_circle 가 호출.
func launch(start: Vector2, direction: Vector2, speed_mul: float = 1.0) -> void:
	var preset: Dictionary = GameConfig.CIRCLE_PRESETS[circle_size]
	position = start
	velocity = direction.normalized() * preset.speed * speed_mul


func _reset() -> void:
	super._reset()
	var preset: Dictionary = GameConfig.CIRCLE_PRESETS[circle_size]
	_radius = preset.radius
	_color = preset.color
	# 히트박스를 탄막 반경에 맞춰 활성화
	if _hit_box and _hit_box.shape is CircleShape2D:
		(_hit_box.shape as CircleShape2D).radius = _radius
		_hit_box.set_deferred("disabled", false)


func _draw() -> void:
	# 본체 + 외곽선
	draw_circle(Vector2.ZERO, _radius, _color)
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 24, Color(1, 1, 1, 0.5), 1.0)
