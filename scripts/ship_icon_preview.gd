extends Node2D

const COLS: int = 7
const ROWS: int = 2
const GAP_X: float = 150.0
const GAP_Y: float = 140.0
const LINE_WIDTH: float = 6.0
const LINE_COLOR: Color = Color("#111111")

const PLAYER_COLOR := Color(0.0, 0.6, 1.0, 1.0)
const ENEMY_COLOR  := Color(1.0, 0.2, 0.2, 1.0)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var entries := ShipIconGenerator.get_all_entries(ShipIconGenerator.Category.SHIP)
	var count := entries.size()
	var rows_needed := ceili(float(count) / float(COLS))
	var total_w: float = COLS * ShipIconGenerator.ICON_SIZE + float(COLS - 1) * (GAP_X - ShipIconGenerator.ICON_SIZE)
	var total_h: float = rows_needed * ShipIconGenerator.ICON_SIZE + float(rows_needed - 1) * (GAP_Y - ShipIconGenerator.ICON_SIZE)
	var offset_x: float = (get_viewport_rect().size.x - total_w) / 2.0
	var offset_y: float = (get_viewport_rect().size.y - total_h) / 2.0

	for i: int in entries.size():
		var col: int = i % COLS
		var row: int = i / COLS
		var cx: float = offset_x + col * GAP_X
		var cy: float = offset_y + row * GAP_Y
		_draw_icon(entries[i], cx, cy, ShipIconGenerator.ICON_SIZE, LINE_COLOR)
		_draw_label(entries[i].name_zh, cx, cy, ShipIconGenerator.ICON_SIZE)

func _draw_icon(entry: ShipIconGenerator.IconEntry, cx: float, cy: float, size: float, col: Color) -> void:
	var scale_val: float = size / ShipIconGenerator.ICON_VIEWBOX
	var path: Array = entry.path
	var last_pt := Vector2.ZERO
	var sub_path: Array = []

	draw_set_transform(Vector2(cx, cy), 0.0, Vector2(scale_val, scale_val))
	for cmd: Array in path:
		if cmd.is_empty():
			continue
		var t: String = cmd[0]
		match t:
			"M":
				last_pt = Vector2(cmd[1], cmd[2])
				sub_path.append(last_pt)
			"L":
				draw_line(last_pt, Vector2(cmd[1], cmd[2]), col, LINE_WIDTH, true)
				last_pt = Vector2(cmd[1], cmd[2])
				sub_path.append(last_pt)
			"Q":
				if cmd.size() >= 5:
					var p0 := last_pt
					var p1 := Vector2(cmd[1], cmd[2])
					var p2 := Vector2(cmd[3], cmd[4])
					for j: int in range(1, 13):
						var tt: float = float(j) / 12.0
						var mt: float = 1.0 - tt
						var pt := Vector2(
							mt * mt * p0.x + 2.0 * mt * tt * p1.x + tt * tt * p2.x,
							mt * mt * p0.y + 2.0 * mt * tt * p1.y + tt * tt * p2.y
						)
						draw_line(last_pt, pt, col, LINE_WIDTH, true)
						last_pt = pt
					sub_path.append(last_pt)
			"Z":
				if not sub_path.is_empty():
					draw_line(last_pt, sub_path[0], col, LINE_WIDTH, true)
					last_pt = sub_path[0]

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_label(text: String, cx: float, cy: float, size: float) -> void:
	draw_string(
		ThemeDB.fallback_font,
		Vector2(cx, cy + 4),
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		20,
		Color("#111111")
	)
