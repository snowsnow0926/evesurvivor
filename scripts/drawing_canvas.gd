extends Control

const VIEWBOX: float = 100.0

enum CanvasKind { DRAW, PREVIEW }

var _kind: CanvasKind = CanvasKind.DRAW
var _editor: Control = null

func setup(editor_node: Control, kind: CanvasKind) -> void:
	_editor = editor_node
	_kind = kind

func _draw() -> void:
	if _editor == null:
		return
	match _kind:
		CanvasKind.DRAW:
			_draw_grid()
			_draw_segments()
			_draw_selection_handles()
			_draw_marquee()
			_draw_mouse_preview()
		CanvasKind.PREVIEW:
			_draw_preview()

func _draw_grid() -> void:
	var scale_factor: float = min(size.x, size.y) / VIEWBOX
	var offset: Vector2 = (size - Vector2(VIEWBOX, VIEWBOX) * scale_factor) * 0.5
	var grid_col := Color(0.28, 0.28, 0.32, 1.0)
	var major_col := Color(0.45, 0.45, 0.5, 1.0)
	var outline_col := Color(0.6, 0.6, 0.65, 1.0)

	var step: float = 10.0
	var i: float = 0.0
	while i <= VIEWBOX:
		var col: Color = major_col if fmod(i, 50.0) < 0.1 else grid_col
		var w: float = 1.5 if fmod(i, 50.0) < 0.1 else 0.5
		draw_line(
			Vector2(i * scale_factor + offset.x, offset.y),
			Vector2(i * scale_factor + offset.x, VIEWBOX * scale_factor + offset.y),
			col, w)
		draw_line(
			Vector2(offset.x, i * scale_factor + offset.y),
			Vector2(VIEWBOX * scale_factor + offset.x, i * scale_factor + offset.y),
			col, w)
		i += step

	draw_line(Vector2(offset.x, offset.y), Vector2(VIEWBOX * scale_factor + offset.x, offset.y), outline_col, 2.0)
	draw_line(Vector2(VIEWBOX * scale_factor + offset.x, offset.y), Vector2(VIEWBOX * scale_factor + offset.x, VIEWBOX * scale_factor + offset.y), outline_col, 2.0)
	draw_line(Vector2(VIEWBOX * scale_factor + offset.x, VIEWBOX * scale_factor + offset.y), Vector2(offset.x, VIEWBOX * scale_factor + offset.y), outline_col, 2.0)
	draw_line(Vector2(offset.x, VIEWBOX * scale_factor + offset.y), Vector2(offset.x, offset.y), outline_col, 2.0)

func _draw_segments() -> void:
	var segments: Array = _editor.get_segments()
	var last_pt: Vector2 = Vector2.ZERO
	var scale_factor: float = min(size.x, size.y) / VIEWBOX
	var offset: Vector2 = (size - Vector2(VIEWBOX, VIEWBOX) * scale_factor) * 0.5

	for seg in segments:
		var seg_type: String = seg.type
		var pts: Array = seg.points
		var seg_col: Color = seg.color
		var seg_width: float = seg.width
		var scaled_w: float = seg_width * scale_factor

		match seg_type:
			"M":
				if not pts.is_empty():
					last_pt = pts[0]
					draw_circle(_vb_to_screen(last_pt, scale_factor, offset), scaled_w * 0.6, seg_col)
			"L":
				if not pts.is_empty():
					draw_line(_vb_to_screen(last_pt, scale_factor, offset), _vb_to_screen(pts[0], scale_factor, offset), seg_col, scaled_w)
					last_pt = pts[0]
			"Q":
				if pts.size() >= 2:
					_draw_bezier(last_pt, pts[0], pts[1], seg_col, scaled_w, scale_factor, offset)
					last_pt = pts[1]

func _draw_selection_handles() -> void:
	var sel_data: Dictionary = _editor.get_selection_data()
	var scale_factor: float = min(size.x, size.y) / VIEWBOX
	var offset: Vector2 = (size - Vector2(VIEWBOX, VIEWBOX) * scale_factor) * 0.5
	var segments: Array = _editor.get_segments()

	for seg_idx: int in range(segments.size()):
		var seg = segments[seg_idx]
		var pts: Array = seg.points
		var seg_col: Color = seg.color
		var seg_width: float = seg.width
		var is_sel: bool = sel_data.get("valid") and sel_data.get("seg_idx") == seg_idx

		for p_idx: int in range(pts.size()):
			var screen_pt: Vector2 = _vb_to_screen(pts[p_idx], scale_factor, offset)
			if is_sel:
				draw_arc(screen_pt, 9.0, 0.0, TAU, 16, Color(0.0, 0.85, 1.0, 0.8), 2.0, true)
				draw_arc(screen_pt, 5.0, 0.0, TAU, 16, Color(0.0, 0.85, 1.0, 1.0), 1.5, true)
			else:
				draw_circle(screen_pt, 3.5, Color(seg_col.r, seg_col.g, seg_col.b, 0.75))

		if is_sel and pts.size() >= 2:
			var prev_screen: Vector2 = _vb_to_screen(pts[0], scale_factor, offset)
			for p_idx: int in range(1, pts.size()):
				var cur_screen: Vector2 = _vb_to_screen(pts[p_idx], scale_factor, offset)
				draw_line(prev_screen, cur_screen, Color(0.0, 0.85, 1.0, 0.45), seg_width * scale_factor + 5.0)
				prev_screen = cur_screen

func _draw_marquee() -> void:
	var mdata: Dictionary = _editor.get_marquee_rect()
	if not mdata.get("active"):
		return
	var scale_factor: float = min(size.x, size.y) / VIEWBOX
	var offset: Vector2 = (size - Vector2(VIEWBOX, VIEWBOX) * scale_factor) * 0.5
	var start: Vector2 = _vb_to_screen(mdata.get("start"), scale_factor, offset)
	var end_pos: Vector2 = _vb_to_screen(mdata.get("end"), scale_factor, offset)
	var r := Rect2(start, end_pos - start)
	if r.size.x < 0:
		r.position.x += r.size.x
		r.size.x = -r.size.x
	if r.size.y < 0:
		r.position.y += r.size.y
		r.size.y = -r.size.y
	var box := r.abs()
	var fill_col := Color(0.0, 0.6, 1.0, 0.08)
	var border_col := Color(0.0, 0.85, 1.0, 0.7)
	draw_rect(box, fill_col, true)
	draw_rect(box, border_col, false, 1.5)

func _draw_bezier(p0: Vector2, p1: Vector2, p2: Vector2, col: Color, w: float, scale_factor: float, offset: Vector2) -> void:
	var prev: Vector2 = _vb_to_screen(p0, scale_factor, offset)
	var steps: int = 20
	for k: int in range(1, steps + 1):
		var t: float = float(k) / float(steps)
		var mt: float = 1.0 - t
		var pt := Vector2(
			mt * mt * p0.x + 2.0 * mt * t * p1.x + t * t * p2.x,
			mt * mt * p0.y + 2.0 * mt * t * p1.y + t * t * p2.y
		)
		var cur: Vector2 = _vb_to_screen(pt, scale_factor, offset)
		draw_line(prev, cur, col, w)
		prev = cur

func _draw_mouse_preview() -> void:
	var state: Dictionary = _editor.get_draw_state()
	var drawing: bool = state.get("drawing")
	var current_tool: int = state.get("current_tool")
	var current_color: Color = state.get("current_color")
	var current_width: float = state.get("current_width")
	var draw_start: Vector2 = state.get("draw_start")
	var curve_step: int = state.get("curve_step")
	var curve_p0: Vector2 = state.get("curve_p0")
	var curve_p1: Vector2 = state.get("curve_p1")

	if not drawing:
		return

	var scale_factor: float = min(size.x, size.y) / VIEWBOX
	var offset: Vector2 = (size - Vector2(VIEWBOX, VIEWBOX) * scale_factor) * 0.5
	var scaled_w: float = current_width * scale_factor

	if current_tool == 0:
		var cur := _screen_to_vb(get_global_mouse_position(), scale_factor, offset)
		draw_line(_vb_to_screen(draw_start, scale_factor, offset), _vb_to_screen(cur, scale_factor, offset), current_color, scaled_w)
	elif current_tool == 1 and curve_step == 1:
		var cur := _screen_to_vb(get_global_mouse_position(), scale_factor, offset)
		var p0s := _vb_to_screen(curve_p0, scale_factor, offset)
		var p1s := _vb_to_screen(curve_p1, scale_factor, offset)
		var p2s := _vb_to_screen(cur, scale_factor, offset)
		draw_line(p0s, p1s, current_color, scaled_w)
		var faded_col := Color(current_color.r, current_color.g, current_color.b, 0.4)
		draw_line(p1s, p2s, faded_col, scaled_w * 0.5)
		draw_circle(p0s, scaled_w, current_color)
		draw_circle(p1s, scaled_w, Color(1.0, 0.8, 0.0))
		_draw_bezier(curve_p0, curve_p1, cur, current_color, scaled_w, scale_factor, offset)

func _draw_preview() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 1.0))

	var info: Dictionary = _editor.get_selected_info()
	var selected_id: String = info.get("selected_icon_id")
	var selected_cat_raw = info.get("selected_category")
	if selected_id.is_empty():
		return

	var entry = ShipIconGenerator.get_entry(selected_cat_raw, selected_id)
	if entry == null:
		return

	var scale_factor: float = min(size.x, size.y) / VIEWBOX
	var offset: Vector2 = (size - Vector2(VIEWBOX, VIEWBOX) * scale_factor) * 0.5
	var path: Array = entry.path
	var last_pt := Vector2.ZERO
	var sub_path: Array = []
	var col := Color(0.066, 0.066, 0.067, 1.0)
	var lw: float = 6.0 * scale_factor

	for cmd: Array in path:
		if cmd.is_empty():
			continue
		var t: String = cmd[0]
		match t:
			"M":
				last_pt = Vector2(cmd[1], cmd[2])
				sub_path.append(last_pt)
				draw_circle(last_pt * scale_factor + offset, lw * 0.6, col)
			"L":
				var next_pt := Vector2(cmd[1], cmd[2])
				draw_line(last_pt * scale_factor + offset, next_pt * scale_factor + offset, col, lw, true)
				last_pt = next_pt
				sub_path.append(last_pt)
			"Q":
				if cmd.size() >= 5:
					var p0 := last_pt
					var cp := Vector2(cmd[1], cmd[2])
					var p2 := Vector2(cmd[3], cmd[4])
					for j: int in range(1, 13):
						var tt: float = float(j) / 12.0
						var mt: float = 1.0 - tt
						var pt := Vector2(
							mt * mt * p0.x + 2.0 * mt * tt * cp.x + tt * tt * p2.x,
							mt * mt * p0.y + 2.0 * mt * tt * cp.y + tt * tt * p2.y
						)
						draw_line(last_pt * scale_factor + offset, pt * scale_factor + offset, col, lw, true)
						last_pt = pt
					sub_path.append(last_pt)
			"Z":
				if not sub_path.is_empty():
					draw_line(last_pt * scale_factor + offset, sub_path[0] * scale_factor + offset, col, lw, true)
					last_pt = sub_path[0]

func _vb_to_screen(vb_pos: Vector2, scale_factor: float, offset: Vector2) -> Vector2:
	return Vector2(vb_pos.x * scale_factor + offset.x, vb_pos.y * scale_factor + offset.y)

func _screen_to_vb(screen_pos: Vector2, scale_factor: float, offset: Vector2) -> Vector2:
	var local: Vector2 = screen_pos - global_position - offset
	return Vector2(local.x / scale_factor, local.y / scale_factor)
