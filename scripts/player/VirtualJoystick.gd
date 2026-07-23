extends Control
## 가상 조이스틱 — 화면 어디든 터치하면 그 점을 중심으로 조이스틱이 동작.
## 첫 손가락의 드래그 벡터를 Player.move_vector 로 전달한다.
## 데스크탑은 emulate_touch_from_mouse 로 마우스가 터치로 변환되므로 동일 동작.

const MAX_RADIUS := 90.0   # 조이스틱 최대 드래그 반경(시각 + 입력 계산 기준)

var _touching := false
var _origin := Vector2.ZERO      # 터치 시작 지점(조이스틱 중심)
var _current := Vector2.ZERO     # 현재 드래그 지점
var _touch_index := -1           # 추적 중인 터치 인덱스 (멀티터치 시 첫 손가락만)

var player: Player = null        # 입력을 전달할 플레이어 (Main 씬이 설정)


func _ready() -> void:
	# 전체 화면을 덮는 투명 Control
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # 입력은 _input 으로 직접 처리
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_over.connect(_on_game_over)


func _on_game_started() -> void:
	_touching = false
	_touch_index = -1
	_apply_zero()
	queue_redraw()


func _on_game_over(_final_score: int) -> void:
	_touching = false
	_touch_index = -1
	_apply_zero()
	queue_redraw()


func _apply_zero() -> void:
	if is_instance_valid(player):
		player.move_vector = Vector2.ZERO


# 모든 입력을 최상위에서 선점 처리
func _input(event: InputEvent) -> void:
	# 플레이 중일 때만 조이스틱 동작 (메뉴/게임오버 터치는 Main이 시작/재시작으로 사용)
	if GameManager.current_state != GameManager.State.PLAYING:
		return
	if not is_instance_valid(player) or not player.is_alive:
		return

	# 모바일 터치 (데스크탑 마우스도 emulate_touch_from_mouse 로 이쪽으로 진입)
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and not _touching:
			# 첫 터치 시작 → 조이스틱 중점 고정
			_touching = true
			_touch_index = t.index
			_origin = t.position
			_current = t.position
			_update_move_vector()
		elif not t.pressed and t.index == _touch_index:
			_end_touch()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if _touching and d.index == _touch_index:
			_current = d.position
			_update_move_vector()


# 드래그 벡터 → 정규화 이동 벡터(-1~1)로 변환해 플레이어에 전달
func _update_move_vector() -> void:
	var delta := _current - _origin
	if delta.length() > MAX_RADIUS:
		delta = delta.normalized() * MAX_RADIUS
	player.move_vector = delta / MAX_RADIUS
	queue_redraw()


func _end_touch() -> void:
	_touching = false
	_touch_index = -1
	_apply_zero()
	queue_redraw()


# 조이스틱 시각 (터치 중일 때만)
func _draw() -> void:
	if not _touching:
		return
	# 시작점 외곽 링
	draw_arc(_origin, MAX_RADIUS, 0.0, TAU, 48, GameConfig.COLOR_JOYSTICK, 2.0)
	# 현재 손가락 위치 핸들
	var handle := _origin + (_current - _origin).limit_length(MAX_RADIUS)
	draw_circle(handle, 22.0, GameConfig.COLOR_JOYSTICK_ACTIVE)
