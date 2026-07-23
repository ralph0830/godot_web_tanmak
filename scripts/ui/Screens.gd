class_name Screens
extends Control
## 전체 화면 오버레이 — 메뉴 / 게임오버 / 순위표 / 이름 입력.
## Main._unhandled_input 이 '아무 데나 탭/R'으로 시작·재시작 처리(이름 입력 중엔 제외).

var _title_label: Label        # "TANMAK"
var _subtitle_label: Label     # 안내 문구
var _gameover_label: Label     # "GAME OVER"
var _score_label: Label        # 최종/최고 점수
var _congrats_label: Label     # 순위 달성 축하/입력 안내
var _name_input: LineEdit      # 이름 3자 입력
var _submit_button: Button     # 등록 버튼

var _final_score := 0
var _rank_to_submit := 0

var score_client = null        # ScoreClient (Main 이 set_clients 로 연결)
var leaderboard = null         # Leaderboard


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # 터치는 자식(LineEdit/Button)과 Main이 처리
	_build()
	EventBus.game_started.connect(func(): hide_all())
	EventBus.game_over.connect(func(s: int): show_game_over(s))
	show_menu()


# Main 이 게임오버 후 순위 표시를 위해 클라이언트/보드 참조와 시그널을 연결
func set_clients(client, board) -> void:
	score_client = client
	leaderboard = board
	if score_client:
		score_client.scores_received.connect(_on_scores_received)
		score_client.submitted.connect(_on_submitted)
		score_client.request_failed.connect(_on_request_failed)


func _build() -> void:
	_title_label = _make_label("TANMAK", 80, Color(0.345, 0.651, 1.0), 0.30)
	_subtitle_label = _make_label("화면을 터치하여 시작", 30, Color(0.9, 0.9, 0.9), 0.94)
	_gameover_label = _make_label("GAME OVER", 56, Color(1.0, 0.32, 0.32), 0.05)
	_gameover_label.visible = false
	_score_label = _make_label("", 30, Color(0.9, 0.9, 0.9), 0.11)
	_score_label.visible = false
	_congrats_label = _make_label("", 28, Color(1.0, 0.84, 0.0), 0.68)
	_congrats_label.visible = false
	# 이름 입력창
	_name_input = LineEdit.new()
	_name_input.max_length = GameConfig.NAME_LENGTH
	_name_input.placeholder_text = "이름 3자"
	_name_input.add_theme_font_size_override("font_size", 28)
	_name_input.size = Vector2(260, 52)
	_name_input.position = Vector2((GameConfig.VIEWPORT_WIDTH - 260) / 2.0, 0.76 * GameConfig.VIEWPORT_HEIGHT)
	_name_input.visible = false
	_name_input.text_submitted.connect(_on_name_submitted)
	add_child(_name_input)
	# 등록 버튼
	_submit_button = Button.new()
	_submit_button.text = "등록"
	_submit_button.add_theme_font_size_override("font_size", 26)
	_submit_button.size = Vector2(160, 52)
	_submit_button.position = Vector2((GameConfig.VIEWPORT_WIDTH - 160) / 2.0, 0.84 * GameConfig.VIEWPORT_HEIGHT)
	_submit_button.visible = false
	_submit_button.pressed.connect(_on_submit_pressed)
	add_child(_submit_button)


# 세로 비율(ratio) 위치의 중앙 정렬 라벨
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


# ------------------------------------------------------------
# 게임오버 → 순위 로드 → (갱신 시) 이름 입력 흐름
# ------------------------------------------------------------
func show_menu() -> void:
	_title_label.visible = true
	_subtitle_label.visible = true
	_subtitle_label.text = "화면을 터치하여 시작"
	_gameover_label.visible = false
	_score_label.visible = false
	_congrats_label.visible = false
	_hide_name_input()
	if leaderboard:
		leaderboard.hide_board()


func show_game_over(final_score: int) -> void:
	_final_score = final_score
	_title_label.visible = false
	_gameover_label.visible = true
	_score_label.text = "Score  %d   ·   Best  %d" % [final_score, GameManager.best_score]
	_score_label.visible = true
	_congrats_label.visible = false
	_hide_name_input()
	_subtitle_label.visible = true
	_subtitle_label.text = "순위 불러오는 중..."
	if leaderboard:
		leaderboard.hide_board()
	if score_client:
		score_client.fetch_scores()
	else:
		_subtitle_label.text = "화면을 터치하여 재시작"


# 순위 수신 → 표시 + 갱신(10위 내) 판단
func _on_scores_received(scores: Array) -> void:
	if leaderboard:
		leaderboard.display(scores)
	_rank_to_submit = _compute_rank(scores, _final_score)
	if _rank_to_submit >= 1 and _rank_to_submit <= GameConfig.LEADERBOARD_SIZE:
		_show_congrats(_rank_to_submit)
	else:
		_subtitle_label.text = "화면을 터치하여 재시작"


# 점수가 들어갈 순위(1-base) 계산, 10위 밖이면 0
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
	_congrats_label.text = "축하드립니다!! %d위 달성!\n이름을 입력해 주세요" % rank
	_congrats_label.visible = true
	_name_input.visible = true
	_name_input.editable = true
	_name_input.text = ""
	_name_input.grab_focus()
	_submit_button.visible = true
	_subtitle_label.text = "이름 3자 입력 후 등록"


# 이름 제출(엔터 또는 버튼)
func _on_name_submitted(text: String) -> void:
	_submit(text)

func _on_submit_pressed() -> void:
	_submit(_name_input.text)

func _submit(player_name: String) -> void:
	player_name = player_name.strip_edges()
	# 정확히 3자 검증
	if player_name.length() != GameConfig.NAME_LENGTH:
		_congrats_label.text = "정확히 %d자(한글/영문/숫자)만 입력!" % GameConfig.NAME_LENGTH
		return
	if score_client:
		_name_input.editable = false
		_submit_button.disabled = true
		score_client.submit_score(player_name, _final_score)


# 제출 완료 → 갱신 순위 표시
func _on_submitted(rank: int, scores: Array) -> void:
	if leaderboard:
		leaderboard.display(scores)
	_hide_name_input()
	_congrats_label.text = "%d위 등록 완료!" % rank
	_congrats_label.visible = true
	_subtitle_label.text = "화면을 터치하여 재시작"


func _on_request_failed(reason: String) -> void:
	_hide_name_input()
	_congrats_label.visible = false
	_subtitle_label.text = "순위 로드 실패 — 터치하여 재시작"
	if leaderboard:
		leaderboard.hide_board()


func _hide_name_input() -> void:
	_name_input.visible = false
	_name_input.editable = false
	_submit_button.visible = false
	_submit_button.disabled = false


# 이름 입력 중인지 — Main 이 재시작 입력 무시 판단용
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
