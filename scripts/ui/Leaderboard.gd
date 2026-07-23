class_name Leaderboard
extends Control
## Leaderboard panel — top 10 (rank / name / score) as a vertical list.

var _row_labels: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_rows()
	visible = false


func _build_rows() -> void:
	for i in GameConfig.LEADERBOARD_SIZE:
		var row := Label.new()
		row.add_theme_font_size_override("font_size", 38)
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# 가로 전체 / 세로는 top 기준 절대 위치 (FULL_RECT 쓰면 bottom anchor 로 행이 늘어남)
		row.anchor_left = 0.0
		row.anchor_top = 0.0
		row.anchor_right = 1.0
		row.anchor_bottom = 0.0
		row.offset_left = 0.0
		row.offset_right = 0.0
		# 10행을 TANMAK 타이틀 아래(200px)부터 넓은 간격으로 배치
		var top: float = 200.0 + i * 64.0
		row.offset_top = top
		row.offset_bottom = top + 54.0
		add_child(row)
		_row_labels.append(row)


func display(scores: Array) -> void:
	visible = true
	for i in GameConfig.LEADERBOARD_SIZE:
		var label: Label = _row_labels[i]
		if i < scores.size():
			var entry: Dictionary = scores[i]
			var name_str := str(entry.get("name", "???"))
			var score_val := int(entry.get("score", 0))
			label.text = "%2d.   %-6s   %6d" % [i + 1, name_str, score_val]
			label.add_theme_color_override("font_color", _rank_color(i + 1))
		else:
			label.text = "%2d.   - - - - - -" % [i + 1]
			label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))


func _rank_color(rank: int) -> Color:
	match rank:
		1: return Color(1.0, 0.84, 0.0)
		2: return Color(0.82, 0.82, 0.88)
		3: return Color(0.88, 0.56, 0.32)
		_: return Color(0.85, 0.85, 0.92)


func hide_board() -> void:
	visible = false
