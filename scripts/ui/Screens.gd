class_name Screens
extends Control
## Full-screen overlay — menu / game over / leaderboard / name entry.
## Main._unhandled_input handles start/restart via tap or R (skipped during name entry).

var _title_label: Label
var _subtitle_label: Label
var _gameover_label: Label
var _score_label: Label
var _congrats_label: Label
var _name_input: LineEdit
var _submit_button: Button

var _final_score := 0
var _rank_to_submit := 0

var score_client = null
var leaderboard = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	EventBus.game_started.connect(func(): hide_all())
	EventBus.game_over.connect(func(s: int): show_game_over(s))
	show_menu()


func set_clients(client, board) -> void:
	score_client = client
	leaderboard = board
	if score_client:
		score_client.scores_received.connect(_on_scores_received)
		score_client.submitted.connect(_on_submitted)
		score_client.request_failed.connect(_on_request_failed)
		# 초기 타이틀 화면 순위 로드
		score_client.fetch_scores()


func _build() -> void:
	_title_label = _make_label("TANMAK", 72, Color(0.345, 0.651, 1.0), 0.05)
	_subtitle_label = _make_label("TAP TO START", 34, Color(0.9, 0.9, 0.9), 0.93)
	_gameover_label = _make_label("GAME OVER", 56, Color(1.0, 0.32, 0.32), 0.05)
	_gameover_label.visible = false
	_score_label = _make_label("", 30, Color(0.9, 0.9, 0.9), 0.11)
	_score_label.visible = false
	_congrats_label = _make_label("", 28, Color(1.0, 0.84, 0.0), 0.68)
	_congrats_label.visible = false
	_name_input = LineEdit.new()
	_name_input.max_length = GameConfig.NAME_LENGTH
	_name_input.placeholder_text = "3 letters"
	_name_input.add_theme_font_size_override("font_size", 28)
	_name_input.size = Vector2(260, 52)
	_name_input.position = Vector2((GameConfig.VIEWPORT_WIDTH - 260) / 2.0, 0.76 * GameConfig.VIEWPORT_HEIGHT)
	_name_input.visible = false
	_name_input.text_submitted.connect(_on_name_submitted)
	add_child(_name_input)
	_submit_button = Button.new()
	_submit_button.text = "SUBMIT"
	_submit_button.add_theme_font_size_override("font_size", 26)
	_submit_button.size = Vector2(160, 52)
	_submit_button.position = Vector2((GameConfig.VIEWPORT_WIDTH - 160) / 2.0, 0.84 * GameConfig.VIEWPORT_HEIGHT)
	_submit_button.visible = false
	_submit_button.pressed.connect(_on_submit_pressed)
	add_child(_submit_button)


func _make_label(text: String, font_size: int, color: Color, ratio: float) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l.offset_top = ratio * GameConfig.VIEWPORT_HEIGHT
	l.offset_bottom = ratio * GameConfig.VIEWPORT_HEIGHT + font_size + 14.0
	add_child(l)
	return l


func show_menu() -> void:
	_title_label.visible = true
	_subtitle_label.visible = true
	_subtitle_label.text = "TAP TO START"
	_gameover_label.visible = false
	_score_label.visible = false
	_congrats_label.visible = false
	_hide_name_input()
	# 순위표는 set_clients() 의 fetch 결과로 표시됨 (여기서 숨기지 않음)


func show_game_over(final_score: int) -> void:
	_final_score = final_score
	_title_label.visible = false
	_gameover_label.visible = true
	_score_label.text = "Score  %d   ·   Best  %d" % [final_score, GameManager.best_score]
	_score_label.visible = true
	_congrats_label.visible = false
	_hide_name_input()
	_subtitle_label.visible = true
	_subtitle_label.text = "Loading scores..."
	if leaderboard:
		leaderboard.hide_board()
	if score_client:
		score_client.fetch_scores()
	else:
		_subtitle_label.text = "TAP TO RESTART"


func _on_scores_received(scores: Array) -> void:
	if leaderboard:
		leaderboard.display(scores)
	# 타이틀(메뉴) 상태에서는 순위 표시만 하고 갱신 판단/축하는 생략
	if GameManager.current_state != GameManager.State.GAME_OVER:
		return
	_rank_to_submit = _compute_rank(scores, _final_score)
	if _rank_to_submit >= 1 and _rank_to_submit <= GameConfig.LEADERBOARD_SIZE:
		_show_congrats(_rank_to_submit)
	else:
		_subtitle_label.text = "TAP TO RESTART"


func _compute_rank(scores: Array, score: int) -> int:
	var rank := 1
	for entry in scores:
		if score >= int(entry.get("score", 0)):
			break
		rank += 1
	if rank > GameConfig.LEADERBOARD_SIZE:
		return 0
	return rank


func _show_congrats(rank: int) -> void:
	_congrats_label.text = "CONGRATULATIONS!!\n%d PLACE — Enter your name" % rank
	_congrats_label.visible = true
	_name_input.visible = true
	_name_input.editable = true
	_name_input.text = ""
	_name_input.grab_focus()
	_submit_button.visible = true
	_subtitle_label.text = "Type 3 letters, then SUBMIT"


func _on_name_submitted(text: String) -> void:
	_submit(text)

func _on_submit_pressed() -> void:
	_submit(_name_input.text)

func _submit(player_name: String) -> void:
	player_name = player_name.strip_edges()
	if player_name.length() != GameConfig.NAME_LENGTH:
		_congrats_label.text = "Enter exactly %d letters (A-Z 0-9)!" % GameConfig.NAME_LENGTH
		return
	if score_client:
		_name_input.editable = false
		_submit_button.disabled = true
		score_client.submit_score(player_name, _final_score)


func _on_submitted(rank: int, scores: Array) -> void:
	if leaderboard:
		leaderboard.display(scores)
	_hide_name_input()
	_congrats_label.text = "Saved %d place!" % rank
	_congrats_label.visible = true
	_subtitle_label.text = "TAP TO RESTART"


func _on_request_failed(reason: String) -> void:
	_hide_name_input()
	_congrats_label.visible = false
	# 메뉴 상태가 아니면(게임오버) 안내 문구 변경
	if GameManager.current_state == GameManager.State.GAME_OVER:
		_subtitle_label.text = "Load failed — tap to restart"
	if leaderboard and GameManager.current_state == GameManager.State.GAME_OVER:
		leaderboard.hide_board()


func _hide_name_input() -> void:
	_name_input.visible = false
	_name_input.editable = false
	_submit_button.visible = false
	_submit_button.disabled = false


func is_entering_name() -> bool:
	return _name_input.visible


func hide_all() -> void:
	_title_label.visible = false
	_subtitle_label.visible = false
	_gameover_label.visible = false
	_score_label.visible = false
	_congrats_label.visible = false
	_hide_name_input()
	if leaderboard:
		leaderboard.hide_board()
