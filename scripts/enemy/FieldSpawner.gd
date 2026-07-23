class_name FieldSpawner
extends Node2D
## 필드 탄막 스폰 — WaveManager 의 활성 패턴/난이도에 따라 탄막을 생성.
## 보스 웨이브(boss_phase_started)에서는 정지하고 보스가 패턴을 담당한다.

var _running := false
var _spawn_timer := 0.0
var _player_ref: Player = null   # RANDOM_AIM 패턴용 플레이어 참조


func set_player(p: Player) -> void:
	_player_ref = p


func _ready() -> void:
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_over.connect(_on_game_over)
	EventBus.boss_phase_started.connect(_on_boss_start)
	EventBus.boss_phase_ended.connect(_on_boss_end)
	EventBus.request_clear_field.connect(_on_clear_field)
	set_process(false)


func _on_game_started() -> void:
	_running = true
	_spawn_timer = 0.0
	set_process(true)


func _on_game_over(_final_score: int) -> void:
	_stop()


func _on_boss_start() -> void:
	# 보스전에서는 필드 스폰 중단
	_running = false


func _on_boss_end() -> void:
	_running = true


func _on_clear_field() -> void:
	# 정리 요청 — 풀 자체가 clear_all 되므로 여기선 타이머만 리셋
	_spawn_timer = 0.0


func _stop() -> void:
	_running = false
	set_process(false)


func _process(delta: float) -> void:
	if not _running:
		return
	_spawn_timer += delta
	if _spawn_timer >= WaveManager.get_spawn_interval():
		_spawn_timer = 0.0
		_spawn_once()


# 한 번의 스폰 — 활성 패턴 중 하나를 무작위 선택
func _spawn_once() -> void:
	var patterns: Array = WaveManager.get_active_patterns()
	if patterns.is_empty():
		return
	var types: Array = WaveManager.get_available_bullet_types()
	if types.is_empty():
		return
	var pattern: int = patterns.pick_random()
	var type: int = types.pick_random()
	match pattern:
		WaveData.Pattern.TOP_RAIN:    _pattern_top_rain(type)
		WaveData.Pattern.SIDE_WEAVE:  _pattern_side_weave(type)
		WaveData.Pattern.RING_CENTER: _pattern_ring_center(type)
		WaveData.Pattern.RANDOM_AIM:  _pattern_random_aim(type)


# 타입에 따라 직선 발사 또는 점멸 배치 (점멸은 화면 안 가시 영역으로 보정)
func _fire_or_place(type: int, start: Vector2, dir: Vector2) -> void:
	if type == BulletPool.BulletType.BOMB or type == BulletPool.BulletType.SCATTER:
		var safe := Vector2(
			clampf(start.x, 60.0, GameConfig.VIEWPORT_WIDTH - 60.0),
			clampf(start.y, 120.0, GameConfig.VIEWPORT_HEIGHT - 220.0)
		)
		BulletSpawner.place_telegraph(type, safe)
	else:
		BulletSpawner.fire_circle(type, start, dir, WaveManager.get_speed_multiplier())


# 패턴: 상단 비
func _pattern_top_rain(type: int) -> void:
	var x := randf_range(40.0, GameConfig.VIEWPORT_WIDTH - 40.0)
	_fire_or_place(type, Vector2(x, -30.0), Vector2.DOWN)


# 패턴: 양옆 수평 진입
func _pattern_side_weave(type: int) -> void:
	var from_left := randf() > 0.5
	var y := randf_range(120.0, GameConfig.VIEWPORT_HEIGHT * 0.6)
	var start := Vector2(-30.0 if from_left else GameConfig.VIEWPORT_WIDTH + 30.0, y)
	var dir := Vector2.RIGHT if from_left else Vector2.LEFT
	_fire_or_place(type, start, dir)


# 패턴: 중앙 원형 확산 (한 번에 여러 발)
func _pattern_ring_center(type: int) -> void:
	if type == BulletPool.BulletType.BOMB or type == BulletPool.BulletType.SCATTER:
		# 점멸 타입은 단일 배치
		var p := Vector2(GameConfig.VIEWPORT_WIDTH / 2.0, GameConfig.VIEWPORT_HEIGHT * 0.3)
		_fire_or_place(type, p, Vector2.ZERO)
		return
	var center := Vector2(GameConfig.VIEWPORT_WIDTH / 2.0, GameConfig.VIEWPORT_HEIGHT * 0.3)
	var n := 10
	for i in n:
		var a := TAU * i / n
		BulletSpawner.fire_circle(type, center, Vector2(cos(a), sin(a)), WaveManager.get_speed_multiplier())


# 패턴: 화면 밖 랜덤 지점 → 플레이어 조준
func _pattern_random_aim(type: int) -> void:
	var start := _random_edge_point()
	var target: Vector2 = _player_ref.position if is_instance_valid(_player_ref) else Vector2(GameConfig.VIEWPORT_WIDTH / 2.0, GameConfig.VIEWPORT_HEIGHT / 2.0)
	var dir := (target - start).normalized()
	_fire_or_place(type, start, dir)


# 화면 테두리 바깥 임의 점
func _random_edge_point() -> Vector2:
	var side := randi() % 3   # 상/좌/우 (하단은 플레이어 구역)
	match side:
		0: return Vector2(randf_range(0.0, GameConfig.VIEWPORT_WIDTH), -30.0)
		1: return Vector2(GameConfig.VIEWPORT_WIDTH + 30.0, randf_range(0.0, GameConfig.VIEWPORT_HEIGHT * 0.7))
		_: return Vector2(-30.0, randf_range(0.0, GameConfig.VIEWPORT_HEIGHT * 0.7))
