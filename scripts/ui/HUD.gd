class_name HUD
extends Control
## 게임 HUD — 점수 / 웨이브 / 난이도 배수 표시 (코드로 구성한 라벨).

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # 터치가 조이스틱/화면으로 통과
	# 점수(상단 중앙), 웨이브(좌), 난이도(우)
	var score_label := _make_label("SCORE 0", 42, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 12.0)
	_make_label("WAVE 1", 24, Color(0.8, 0.8, 0.8), HORIZONTAL_ALIGNMENT_LEFT, 60.0)
	_make_label("x1.0", 22, Color(1.0, 0.66, 0.34), HORIZONTAL_ALIGNMENT_RIGHT, 60.0)
	# 시그널 → 라벨 갱신
	EventBus.score_changed.connect(func(s: int): score_label.text = "SCORE %d" % s)
	EventBus.wave_changed.connect(func(w: int):
		_set_label_text(0, "WAVE %d" % w))
	EventBus.difficulty_changed.connect(func(m: float):
		_set_label_text(1, "x%.1f" % m))


# 인덱스(1=웨이브, 2=난이도) 라벨 텍스트 갱신
func _set_label_text(index: int, text: String) -> void:
	var labels := get_children()
	if index < labels.size() and labels[index] is Label:
		(labels[index] as Label).text = text


# 라벨 생성 헬퍼 — 전체 화면 Control, 상단 정렬, 좌/우/중앙
func _make_label(text: String, font_size: int, color: Color, halign: int, top: float) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = halign
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l.offset_top = top
	l.offset_left = 16.0 if halign == HORIZONTAL_ALIGNMENT_LEFT else 0.0
	l.offset_right = -16.0 if halign == HORIZONTAL_ALIGNMENT_RIGHT else 0.0
	add_child(l)
	return l
