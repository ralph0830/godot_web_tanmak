class_name Main
extends Node2D
## 최상위 씬 컨트롤러 — 자식 노드 연결, 시작/재시작 입력 처리.

@onready var _player: Player = $Player
@onready var _field_spawner: FieldSpawner = $FieldSpawner
@onready var _joystick: Control = $UI/Joystick
@onready var _screens: Screens = $UI/Screens
@onready var _score_client: ScoreClient = $UI/ScoreClient
@onready var _leaderboard: Leaderboard = $UI/Leaderboard


func _ready() -> void:
	# FieldSpawner(조준용) 와 VirtualJoystick 에 플레이어 참조 연결
	_field_spawner.set_player(_player)
	_joystick.player = _player
	# 순위 클라이언트/보드를 Screens 에 연결 (게임오버 순위 표시)
	_screens.set_clients(_score_client, _leaderboard)


func _unhandled_input(event: InputEvent) -> void:
	# 시작/재시작: R키 또는 화면 탭 (단, 플레이 중이 아니고 이름 입력 중이 아닐 때)
	var want_start := false
	if event.is_action_pressed("restart"):
		want_start = true
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		want_start = true

	if want_start and GameManager.current_state != GameManager.State.PLAYING:
		# 순위권 달성으로 이름 입력 중이면 재시작 무시 (입력 보호)
		if _screens.is_entering_name():
			return
		GameManager.start_game()
