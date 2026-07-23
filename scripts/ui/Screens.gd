class_name Screens
extends Control
## 전체 화면 오버레이 — 메뉴(시작 안내) / 게임오버 화면.
## Main._unhandled_input 이 '아무 데나 탭/R'으로 시작·재시작 처리하므로 여기선 표시만 담당.

var _title_label: Label        # "TANMAK"
var _subtitle_label: Label     # 시작 안내
var _gameover_label: Label     # "GAME OVER"
var _score_label: Label        # 최종 점수 / 최고 점수


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # 터치 통과 (Main이 시작 입력 처리)
	_build()
	EventBus.game_started.connect(func(): hide_all())
	EventBus.game_over.connect(func(s: int): show_game_over(s))
	show_menu()


func _build() -> void:
	_title_label = _make_label("TANMAK", 80, Color(0.345, 0.651, 1.0), 0.30)
	_subtitle_label = _make_label("화면을 터치하여 시작", 30, Color(0.9, 0.9, 0.9), 0.46)
	_gameover_label = _make_label("GAME OVER", 64, Color(1.0, 0.32, 0.32), 0.34)
	_gameover_label.visible = false
	_score_label = _make_label("", 30, Color(0.9, 0.9, 0.9), 0.48)
	_score_label.visible = false


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
	l.offset_bottom = ratio * GameConfig.VIEWPORT_HEIGHT + font_size + 12.0
	add_child(l)
	return l


func show_menu() -> void:
	_title_label.visible = true
	_subtitle_label.visible = true
	_subtitle_label.text = "화면을 터치하여 시작"
	_gameover_label.visible = false
	_score_label.visible = false


func show_game_over(final_score: int) -> void:
	_title_label.visible = false
	_gameover_label.visible = true
	_score_label.text = "Score  %d   ·   Best  %d" % [final_score, GameManager.best_score]
	_score_label.visible = true
	_subtitle_label.visible = true
	_subtitle_label.text = "화면을 터치하여 재시작"


func hide_all() -> void:
	_title_label.visible = false
	_subtitle_label.visible = false
	_gameover_label.visible = false
	_score_label.visible = false
