class_name ScatterBullet
extends TelegraphBullet
## 산탄 — 점멸(경고) 후 중심에서 원형으로 작은 총알 N개를 분사.

const TELEGRAPH_RADIUS := 12.0


func _detonate() -> void:
	# 원형 등간격으로 분사 — 풀에서 LinearBullet(소) 획득
	var count := GameConfig.SCATTER_FRAGMENT_COUNT
	var base_speed: float = GameConfig.CIRCLE_PRESETS[GameConfig.CircleSize.SMALL].speed
	# 분사 속도 = 설정 속도 + 난이도 배수
	var mul := WaveManager.get_speed_multiplier() * (GameConfig.SCATTER_FRAGMENT_SPEED / base_speed)
	for i in count:
		var angle := TAU * i / count
		var dir := Vector2(cos(angle), sin(angle))
		var frag: Node2D = BulletPool.acquire(BulletPool.BulletType.CIRCLE_SMALL)
		if frag and frag is LinearBullet:
			(frag as LinearBullet).launch(position, dir, mul)
	_despawn()


func _draw() -> void:
	# 점멸 경고 원 (청색 테두리로 폭탄과 구분)
	var a := FADE_ON if _blink_visible else FADE_OFF
	var col := GameConfig.COLOR_TELEGRAPH
	col.a = a
	draw_circle(Vector2.ZERO, TELEGRAPH_RADIUS, col)
	draw_arc(Vector2.ZERO, TELEGRAPH_RADIUS, 0.0, TAU, 24, Color(0.345, 0.651, 1.0, 1.0), 2.0)
