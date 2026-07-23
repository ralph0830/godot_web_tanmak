class_name BombBullet
extends TelegraphBullet
## 폭탄 — 점멸(경고) 후 범위(AOE) 폭발. 폭발 영역이 플레이어와 겹치면 피격.

const TELEGRAPH_RADIUS := 14.0   # 점멸 단계 시각/경고 반경

var _exploded := false
var _explosion_time := 0.0


func _reset() -> void:
	super._reset()
	_exploded = false
	_explosion_time = 0.0
	# 점멸 단계 히트박스는 비활성(경고만)
	if _hit_box and _hit_box.shape is CircleShape2D:
		(_hit_box.shape as CircleShape2D).radius = GameConfig.BOMB_EXPLOSION_RADIUS


func _detonate() -> void:
	if _exploded:
		return
	_exploded = true
	_phase = Phase.DETONATE
	_explosion_time = 0.0
	# 폭발 순간 히트박스 활성화 → 폭발 반경 내 플레이어 피격
	if _hit_box:
		_hit_box.set_deferred("disabled", false)
	queue_redraw()


func _tick(delta: float) -> void:
	if _exploded:
		# 폭발 유지 시간 동안 표시 후 제거
		_explosion_time += delta
		if _explosion_time >= GameConfig.BOMB_EXPLOSION_DURATION:
			_despawn()
		return
	super._tick(delta)


func _draw() -> void:
	if _exploded:
		# 확장하며 페이드되는 폭발 원
		var p := clampf(_explosion_time / GameConfig.BOMB_EXPLOSION_DURATION, 0.0, 1.0)
		var r := lerpf(GameConfig.BOMB_EXPLOSION_RADIUS * 0.4, GameConfig.BOMB_EXPLOSION_RADIUS, p)
		var col := GameConfig.COLOR_EXPLOSION
		col.a = lerpf(0.9, 0.0, p)
		draw_circle(Vector2.ZERO, r, col)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color(1.0, 0.8, 0.3, 1.0 - p), 3.0)
	else:
		# 점멸 경고 원 (깜빡임)
		var a := FADE_ON if _blink_visible else FADE_OFF
		var col := GameConfig.COLOR_TELEGRAPH
		col.a = a
		draw_circle(Vector2.ZERO, TELEGRAPH_RADIUS, col)
		draw_arc(Vector2.ZERO, TELEGRAPH_RADIUS, 0.0, TAU, 24, Color(1.0, 0.2, 0.2, 1.0), 2.0)
