class_name Leaderboard
extends Control
## 순위표 패널 — 상위 10위(순위 / 이름 / 점수) 표시. 화면 중앙 영역에 세로 목록.

var _row_labels: Array = []   # Label 목록(10개)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # 터치 통과
	_build_rows()
	visible = false


# 10개의 빈 행 생성
func _build_rows() -> void:
	for i in GameConfig.LEADERBOARD_SIZE:
		var row := Label.new()
		row.add_theme_font_size_override("font_size", 26)
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		# 세로 배치: 위에서부터 일정 간격
		var top: float = 260.0 + i * 42.0
		row.offset_top = top
		row.offset_bottom = top + 38.0
		add_child(row)
		_row_labels.append(row)


# scores 배열(점수 내림차순) 표시
func display(scores: Array) -> void:
	visible = true
	for i in GameConfig.LEADERBOARD_SIZE:
		var label: Label = _row_labels[i]
		if i < scores.size():
			var entry: Dictionary = scores[i]
			var name_str := str(entry.get("name", "???"))
			var score_val := int(entry.get("score", 0))
			label.text = "%2d위   %s   %d점" % [i + 1, name_str, score_val]
			label.add_theme_color_override("font_color", _rank_color(i + 1))
		else:
			label.text = "%2d위   %s" % [i + 1, "- - - - - -"]
			label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))


# 순위별 색상 (금/은/동)
func _rank_color(rank: int) -> Color:
	match rank:
		1: return Color(1.0, 0.84, 0.0)
		2: return Color(0.82, 0.82, 0.88)
		3: return Color(0.88, 0.56, 0.32)
		_: return Color(0.85, 0.85, 0.92)


func hide_board() -> void:
	visible = false
