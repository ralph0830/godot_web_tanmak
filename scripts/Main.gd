class_name Main
extends Node2D
## 최상위 씬 컨트롤러 — 자식 노드 연결, 시작/재시작 입력 처리.

@onready var _player: Player = $Player
@onready var _field_spawner: FieldSpawner = $FieldSpawner
@onready var _joystick: Control = $UI/Joystick


func _ready() -> void:
	# FieldSpawner(조준용) 와 VirtualJoystick 에 플레이어 참조 연결
	_field_spawner.set_player(_player)
	_joystick.player = _player


func _unhandled_input(event: InputEvent) -> void:
	# 시작/재시작: R키 또는 화면 탭 (단, 플레이 중이 아닐 때만)
	var want_start := false
	if event.is_action_pressed("restart"):
		want_start = true
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		want_start = true

	if want_start and GameManager.current_state != GameManager.State.PLAYING:
		GameManager.start_game()
