class_name Enemy
extends Node2D
## 보스 — 피격 대상이 아닌 탄막 시전자 (순수 회피 게임).
## 보스 웨이브(boss_phase_started)에서 등장해 회전 나선 탄막 + 간헐적 폭탄/산탄 경고를 시전.

var _active := false
var _fire_timer := 0.0
var _spiral_angle := 0.0
var _center := Vector2.ZERO


func _ready() -> void:
	_center = Vector2(GameConfig.VIEWPORT_WIDTH / 2.0, GameConfig.VIEWPORT_HEIGHT * 0.22)
	position = _center
	visible = false
	set_process(false)
	EventBus.boss_phase_started.connect(_on_boss_start)
	EventBus.boss_phase_ended.connect(_on_boss_end)
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_over.connect(_on_game_over)


func _on_game_started() -> void:
	_hide()


func _on_game_over(_final_score: int) -> void:
	_hide()


func _on_boss_start() -> void:
	_show()


func _on_boss_end() -> void:
	_hide()


func _show() -> void:
	_active = true
	visible = true
	position = _center
	_fire_timer = 0.0
	_spiral_angle = 0.0
	set_process(true)
	queue_redraw()


func _hide() -> void:
	_active = false
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	if not _active:
		return
	_fire_timer += delta
	# 0.09초마다 회전 나선 1스텝 발사
	if _fire_timer >= 0.09:
		_fire_timer = 0.0
		_fire_spiral_step()
		# 간헐적으로 폭탄/산탄 경고 배치
		if randf() < 0.05:
			_place_warning()


# 회전하는 다중 팔 나선 탄막
func _fire_spiral_step() -> void:
	var arms := 5
	var speed_mul := WaveManager.get_speed_multiplier()
	for i in arms:
		var a := _spiral_angle + TAU * i / arms
		BulletSpawner.fire_circle(BulletPool.BulletType.CIRCLE_SMALL, position, Vector2(cos(a), sin(a)), speed_mul)
	_spiral_angle += 0.34


# 플레이어 근처에 폭탄/산탄 경고 배치
func _place_warning() -> void:
	var player_node := get_tree().get_first_node_in_group("player") as Player
	var p := position
	if player_node:
		# 플레이어 주변 무작위 오프셋
		p = player_node.position + Vector2(randf_range(-120, 120), randf_range(-120, 120))
		p.x = clampf(p.x, 60.0, GameConfig.VIEWPORT_WIDTH - 60.0)
		p.y = clampf(p.y, 120.0, GameConfig.VIEWPORT_HEIGHT - 220.0)
	var t := BulletPool.BulletType.BOMB if randf() < 0.5 else BulletPool.BulletType.SCATTER
	BulletSpawner.place_telegraph(t, p)


# 보스 시각 (큰 적색 코어)
func _draw() -> void:
	if not _active:
		return
	var r := 38.0
	draw_circle(Vector2.ZERO, r, Color(0.85, 0.25, 0.35))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(1, 1, 1, 0.8), 3.0)
	draw_circle(Vector2.ZERO, r * 0.4, Color(1.0, 0.9, 0.5))
