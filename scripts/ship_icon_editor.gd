extends Control

const VIEWBOX: float = 100.0

enum Tool { LINE, CURVE }

class DrawSegment:
	var type: String
	var points: Array[Vector2]
	var color: Color
	var width: float

	func _init(t: String, pts: Array[Vector2], col: Color, w: float) -> void:
		type = t
		points = pts
		color = col
		width = w

var _current_tool: Tool = Tool.LINE
var _current_color: Color = Color(0.066, 0.066, 0.067, 1)
var _current_width: float = 6.0

var _segments: Array[DrawSegment] = []
var _history: Array = []
var _history_index: int = -1

var _selected_category: ShipIconGenerator.Category = ShipIconGenerator.Category.SHIP
var _selected_icon_id: String = ""

var _drawing: bool = false
var _draw_start: Vector2 = Vector2.ZERO
var _curve_step: int = 0
var _curve_p0: Vector2 = Vector2.ZERO
var _curve_p1: Vector2 = Vector2.ZERO
var _curve_p2: Vector2 = Vector2.ZERO

var _category_headers: Array[Button] = []
var _category_items: Array[Control] = []
var _item_buttons: Array[Button] = []

func _ready() -> void:
	_set_status("就绪")
	_connect_signals()
	_build_category_tree()
	_select_first_icon()
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed:
			if event.keycode == KEY_Z:
				_on_undo()
			elif event.keycode == KEY_Y:
				_on_redo()
	if event is InputEventMouseMotion:
		var canvas: Control = $MainHSplit/CanvasPanel/DrawingCanvas
		if canvas.is_visible_in_tree():
			var rect: Rect2 = canvas.get_global_rect()
			if rect.has_point(get_global_mouse_position()):
				var vb: Vector2 = _screen_to_viewbox(event.global_position, rect)
				$StatusBar/StatusHBox/CoordLabel.text = "(%.1f, %.1f)" % [vb.x, vb.y]
			else:
				$StatusBar/StatusHBox/CoordLabel.text = ""
	if event is InputEventMouseButton:
		var canvas: Control = $MainHSplit/CanvasPanel/DrawingCanvas
		if not canvas.is_visible_in_tree():
			return
		var rect: Rect2 = canvas.get_global_rect()
		if not rect.has_point(get_global_mouse_position()):
			return
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_on_mouse_down(mb.global_position, rect)
			else:
				_on_mouse_up(mb.global_position, rect)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_cancel_draw()

func _connect_signals() -> void:
	$MainHSplit/LeftPanel/LeftScroll/LeftVBox/ToolHBox/LineBtn.pressed.connect(_on_line_tool)
	$MainHSplit/LeftPanel/LeftScroll/LeftVBox/ToolHBox/CurveBtn.pressed.connect(_on_curve_tool)
	$MainHSplit/LeftPanel/LeftScroll/LeftVBox/ColorPicker.color_changed.connect(_on_color_changed)
	$MainHSplit/LeftPanel/LeftScroll/LeftVBox/WidthHBox/WidthSlider.value_changed.connect(_on_width_changed)
	$MainHSplit/LeftPanel/LeftScroll/LeftVBox/ActionGrid/UndoBtn.pressed.connect(_on_undo)
	$MainHSplit/LeftPanel/LeftScroll/LeftVBox/ActionGrid/RedoBtn.pressed.connect(_on_redo)
	$MainHSplit/LeftPanel/LeftScroll/LeftVBox/ActionGrid/ClearBtn.pressed.connect(_on_clear)
	$MainHSplit/LeftPanel/LeftScroll/LeftVBox/ActionGrid/SaveBtn.pressed.connect(_on_save)

func _build_category_tree() -> void:
	var container: VBoxContainer = $MainHSplit/LeftPanel/LeftScroll/LeftVBox/CategoryList
	for c: Button in _category_headers:
		c.queue_free()
	for c: Control in _category_items:
		c.queue_free()
	_category_headers.clear()
	_category_items.clear()
	_item_buttons.clear()

	var categories := [
		[ShipIconGenerator.Category.SHIP, "舰船", "S"],
		[ShipIconGenerator.Category.ENEMY, "敌人", "E"],
		[ShipIconGenerator.Category.BUILDING, "建筑", "B"],
	]

	for cat_data: Array in categories:
		var cat: ShipIconGenerator.Category = cat_data[0]
		var label: String = cat_data[1]
		var abbr: String = cat_data[2]
		var count: int = ShipIconGenerator.get_all_icon_ids(cat).size()

		var header := Button.new()
		header.text = "[%s] %s (%d)" % [abbr, label, count]
		header.custom_minimum_size.y = 30
		header.pressed.connect(_on_category_header.bind(cat))
		container.add_child(header)
		_category_headers.append(header)

		var item_container := VBoxContainer.new()
		item_container.visible = false
		container.add_child(item_container)
		_category_items.append(item_container)

		var entries: Array = ShipIconGenerator.get_all_entries(cat)
		for entry in entries:
			var btn := Button.new()
			btn.text = "  %s" % entry.name_zh
			btn.custom_minimum_size.y = 26
			btn.pressed.connect(_on_icon_item.bind(entry.id, cat))
			item_container.add_child(btn)
			_item_buttons.append(btn)

		var add_btn := Button.new()
		add_btn.text = "  + 新增"
		add_btn.custom_minimum_size.y = 24
		add_btn.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		add_btn.pressed.connect(_on_add_icon.bind(cat))
		item_container.add_child(add_btn)
		_item_buttons.append(add_btn)

	_show_category(ShipIconGenerator.Category.SHIP)

func _show_category(cat: ShipIconGenerator.Category) -> void:
	for i: int in ShipIconGenerator.Category.size():
		var header: Button = _category_headers[i] if i < _category_headers.size() else null
		var items: Control = _category_items[i] if i < _category_items.size() else null
		if header:
			var is_selected: bool = (i == cat)
			var style: StyleBoxFlat = _make_header_style(is_selected)
			header.add_theme_stylebox_override("normal", style)
		if items:
			items.visible = (i == cat)

func _make_header_style(selected: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	if selected:
		s.bg_color = Color(0.0, 0.3, 0.5, 0.4)
	else:
		s.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s

func _on_category_header(cat: ShipIconGenerator.Category) -> void:
	_show_category(cat)
	_selected_category = cat
	_select_first_in_category()

func _select_first_in_category() -> void:
	var ids: Array = ShipIconGenerator.get_all_icon_ids(_selected_category)
	if not ids.is_empty():
		_select_icon(ids[0], _selected_category)
	else:
		_selected_icon_id = ""
		_segments.clear()
		_history.clear()
		_history_index = -1
		_set_status("该分类暂无图标")

func _select_first_icon() -> void:
	var ids: Array = ShipIconGenerator.get_all_icon_ids(_selected_category)
	if not ids.is_empty():
		_select_icon(ids[0], _selected_category)
	else:
		_selected_icon_id = ""
		_segments.clear()

func _select_icon(icon_id: String, cat: ShipIconGenerator.Category) -> void:
	if _selected_icon_id == icon_id:
		return
	_save_to_generator()
	_selected_category = cat
	_selected_icon_id = icon_id
	_load_from_generator()
	_update_item_buttons()
	_set_status("当前: %s" % icon_id)

func _update_item_buttons() -> void:
	for btn: Button in _item_buttons:
		btn.remove_theme_color_override("font_color")
		btn.remove_theme_stylebox_override("normal")

func _load_from_generator() -> void:
	_segments.clear()
	_history.clear()
	_history_index = -1
	var entry: ShipIconGenerator.IconEntry = ShipIconGenerator.get_entry(_selected_category, _selected_icon_id)
	if entry == null:
		return
	for cmd: Array in entry.path:
		if cmd.is_empty():
			continue
		var t: String = cmd[0]
		var pts: Array[Vector2] = []
		if t == "M" and cmd.size() >= 3:
			pts.append(Vector2(cmd[1], cmd[2]))
		elif t == "L" and cmd.size() >= 3:
			pts.append(Vector2(cmd[1], cmd[2]))
		elif t == "Q" and cmd.size() >= 5:
			pts.append(Vector2(cmd[1], cmd[2]))
			pts.append(Vector2(cmd[3], cmd[4]))
		if not pts.is_empty():
			var seg := DrawSegment.new(t, pts, _current_color, _current_width)
			_segments.append(seg)
	_save_history()

func _save_to_generator() -> void:
	if _selected_icon_id.is_empty():
		return
	var path_data: Array = _segments_to_path_data()
	ShipIconGenerator.set_icon_path(_selected_icon_id, path_data)

func _on_icon_item(icon_id: String, cat: ShipIconGenerator.Category) -> void:
	_select_icon(icon_id, cat)

func _on_add_icon(cat: ShipIconGenerator.Category) -> void:
	var existing: Array = ShipIconGenerator.get_all_icon_ids(cat)
	var suffix: int = 1
	var base: String
	match cat:
		ShipIconGenerator.Category.SHIP: base = "ship"
		ShipIconGenerator.Category.ENEMY: base = "enemy"
		ShipIconGenerator.Category.BUILDING: base = "building"
	var new_id: String = base + "_%03d" % suffix
	while new_id in existing:
		suffix += 1
		new_id = base + "_%03d" % suffix

	var all_entries: Array[Dictionary] = []
	var path_str := "res://resources/icon_definitions.json"
	var file := FileAccess.open(path_str, FileAccess.READ)
	if file != null:
		var json_str := file.get_as_text()
		file.close()
		var json := JSON.new()
		if json.parse(json_str) == OK:
			var data = json.get_data()
			if data is Dictionary:
				all_entries = [data]
			elif data is Array:
				all_entries = data

	var cat_key: String
	match cat:
		ShipIconGenerator.Category.SHIP: cat_key = "ships"
		ShipIconGenerator.Category.ENEMY: cat_key = "enemies"
		ShipIconGenerator.Category.BUILDING: cat_key = "buildings"

	var new_entry: Dictionary = {
		"id": new_id,
		"name_zh": "新图标_" + new_id,
		"name_en": "New_" + new_id,
		"path": []
	}

	var found: bool = false
	for i: int in all_entries.size():
		if all_entries[i] is Dictionary and all_entries[i].has(cat_key):
			all_entries[i][cat_key].append(new_entry)
			found = true
			break

	if not found:
		var root: Dictionary = {}
		if not all_entries.is_empty() and all_entries[0] is Dictionary:
			root = all_entries[0]
		else:
			root = {"ships": [], "enemies": [], "buildings": []}
			all_entries = [root]
		root[cat_key].append(new_entry)

	_write_json_and_reload(all_entries)
	_set_status("已新增: %s" % new_id)

func _on_line_tool() -> void:
	_current_tool = Tool.LINE
	_update_tool_ui()

func _on_curve_tool() -> void:
	_current_tool = Tool.CURVE
	_update_tool_ui()

func _update_tool_ui() -> void:
	var line_btn: Button = $MainHSplit/LeftPanel/LeftScroll/LeftVBox/ToolHBox/LineBtn
	var curve_btn: Button = $MainHSplit/LeftPanel/LeftScroll/LeftVBox/ToolHBox/CurveBtn
	match _current_tool:
		Tool.LINE:
			line_btn.add_theme_color_override("font_color", Color(0.0, 0.8, 1.0))
			curve_btn.remove_theme_color_override("font_color")
		Tool.CURVE:
			curve_btn.add_theme_color_override("font_color", Color(0.0, 0.8, 1.0))
			line_btn.remove_theme_color_override("font_color")

func _on_color_changed(color: Color) -> void:
	_current_color = color

func _on_width_changed(value: float) -> void:
	_current_width = value
	$MainHSplit/LeftPanel/LeftScroll/LeftVBox/WidthHBox/WidthVal.text = str(int(value))

func _on_mouse_down(pos: Vector2, rect: Rect2) -> void:
	_drawing = true
	_draw_start = _screen_to_viewbox(pos, rect)
	match _current_tool:
		Tool.LINE:
			pass
		Tool.CURVE:
			_curve_step = 0
			_curve_p0 = _draw_start
			_curve_p1 = _draw_start
			_curve_p2 = _draw_start
	_set_status("绘制中...")

func _on_mouse_up(pos: Vector2, rect: Rect2) -> void:
	if not _drawing:
		return
	_drawing = false
	var end_pos: Vector2 = _screen_to_viewbox(pos, rect)
	match _current_tool:
		Tool.LINE:
			var seg := DrawSegment.new("L", [_draw_start], _current_color, _current_width)
			_segments.append(seg)
			_save_history()
			_set_status("已添加线段 (共 %d 段)" % _segments.size())
		Tool.CURVE:
			_curve_step += 1
			match _curve_step:
				1:
					_curve_p1 = end_pos
					_drawing = true
					_set_status("点击设置控制点，再点击设置终点")
				2:
					_curve_p2 = end_pos
					var seg := DrawSegment.new("Q", [_curve_p1, _curve_p2], _current_color, _current_width)
					_segments.append(seg)
					_save_history()
					_curve_step = 0
					_set_status("已添加曲线 (共 %d 段)" % _segments.size())
	_draw_start = Vector2.ZERO

func _cancel_draw() -> void:
	_drawing = false
	_curve_step = 0
	_set_status("已取消")

func _on_undo() -> void:
	if _history_index < 0:
		return
	_segments.clear()
	if _history_index > 0:
		_history_index -= 1
		_restore_snapshot(_history[_history_index])
	_set_status("撤销")

func _on_redo() -> void:
	if _history_index >= _history.size() - 1:
		return
	_history_index += 1
	_segments.clear()
	_restore_snapshot(_history[_history_index])
	_set_status("重做")

func _on_clear() -> void:
	if _segments.is_empty():
		return
	_save_history()
	_segments.clear()
	_set_status("已清空")

func _on_save() -> void:
	_save_to_generator()
	var json_data: Array = _read_json()
	if json_data.is_empty():
		_set_status("保存失败：无法读取 JSON")
		return

	var cat_key: String
	match _selected_category:
		ShipIconGenerator.Category.SHIP: cat_key = "ships"
		ShipIconGenerator.Category.ENEMY: cat_key = "enemies"
		ShipIconGenerator.Category.BUILDING: cat_key = "buildings"

	var path_data: Array = _segments_to_path_data()
	var updated: bool = false
	for i: int in json_data.size():
		if json_data[i] is Dictionary and json_data[i].has(cat_key):
			var list: Array = json_data[i][cat_key]
			for j: int in list.size():
				if list[j] is Dictionary and list[j].get("id") == _selected_icon_id:
					list[j]["path"] = path_data
					updated = true
					break
		if updated:
			break

	if not updated:
		_set_status("保存失败：未找到图标 ID")
		return

	_write_json_and_reload(json_data)
	_set_status("已保存到 JSON!")

func _segments_to_path_data() -> Array:
	var result: Array = []
	var open_subpath: bool = false
	for seg: DrawSegment in _segments:
		match seg.type:
			"M":
				if open_subpath:
					result.append(["Z"])
				result.append(["M", seg.points[0].x, seg.points[0].y])
				open_subpath = true
			"L":
				if not open_subpath:
					result.append(["M", seg.points[0].x, seg.points[0].y])
					open_subpath = true
				result.append(["L", seg.points[0].x, seg.points[0].y])
			"Q":
				if not open_subpath:
					result.append(["M", seg.points[0].x, seg.points[0].y])
					open_subpath = true
				if seg.points.size() >= 2:
					result.append(["Q", seg.points[0].x, seg.points[0].y, seg.points[1].x, seg.points[1].y])
	return result

func _save_history() -> void:
	var snapshot: Array = []
	for seg: DrawSegment in _segments:
		var pts_copy: Array[Vector2] = []
		for p: Vector2 in seg.points:
			pts_copy.append(p)
		snapshot.append({"type": seg.type, "points": pts_copy, "color": seg.color, "width": seg.width})
	if _history_index < _history.size() - 1:
		_history.resize(_history_index + 1)
	_history.append(snapshot)
	_history_index = _history.size() - 1

func _restore_snapshot(snapshot: Array) -> void:
	for entry: Dictionary in snapshot:
		var pts: Array[Vector2] = []
		for p: Vector2 in entry.points:
			pts.append(p)
		var seg := DrawSegment.new(entry.type, pts, entry.color, entry.width)
		_segments.append(seg)

func _read_json() -> Array:
	var path_str := "res://resources/icon_definitions.json"
	var file := FileAccess.open(path_str, FileAccess.READ)
	if file == null:
		return []
	var json_str := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_str) != OK:
		return []
	var data = json.get_data()
	if data is Dictionary:
		return [data]
	return data as Array

func _write_json_and_reload(data: Array) -> void:
	var path_str := "res://resources/icon_definitions.json"

	var backup_path := path_str + ".bak"
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
	if FileAccess.file_exists(path_str):
		DirAccess.copy_absolute(path_str, backup_path)

	var file := FileAccess.open(path_str, FileAccess.WRITE)
	if file == null:
		_set_status("写入失败: " + str(FileAccess.get_open_error()))
		return

	var root: Dictionary = {}
	if not data.is_empty() and data[0] is Dictionary:
		root = data[0]
	var json_str := JSON.stringify(root, "\t")
	file.store_string(json_str)
	file.close()
	ShipIconGenerator.reload()
	_build_category_tree()
	_select_icon(_selected_icon_id, _selected_category)

func _screen_to_viewbox(screen_pos: Vector2, canvas_rect: Rect2) -> Vector2:
	var local: Vector2 = screen_pos - canvas_rect.position
	var scale_factor: float = min(canvas_rect.size.x, canvas_rect.size.y) / VIEWBOX
	var offset: Vector2 = (canvas_rect.size - Vector2(VIEWBOX, VIEWBOX) * scale_factor) * 0.5
	return Vector2((local.x - offset.x) / scale_factor, (local.y - offset.y) / scale_factor)

func _viewbox_to_screen(vb_pos: Vector2, canvas_rect: Rect2) -> Vector2:
	var scale_factor: float = min(canvas_rect.size.x, canvas_rect.size.y) / VIEWBOX
	var offset: Vector2 = (canvas_rect.size - Vector2(VIEWBOX, VIEWBOX) * scale_factor) * 0.5
	return Vector2(vb_pos.x * scale_factor + offset.x, vb_pos.y * scale_factor + offset.y)

func _set_status(msg: String) -> void:
	$StatusBar/StatusHBox/StatusLabel.text = msg

func _draw() -> void:
	var canvas: Control = $MainHSplit/CanvasPanel/DrawingCanvas
	if canvas.is_visible_in_tree():
		var rect: Rect2 = canvas.get_global_rect()
		_draw_grid(rect)
		_draw_segments(rect)

	var preview_canvas: Control = $MainHSplit/LeftPanel/LeftScroll/LeftVBox/PreviewContainer/PreviewCanvas
	if preview_canvas.is_visible_in_tree():
		var preview_rect := Rect2(preview_canvas.global_position, preview_canvas.size)
		_draw_preview(preview_rect)

func _draw_grid(rect: Rect2) -> void:
	var scale_factor: float = min(rect.size.x, rect.size.y) / VIEWBOX
	var offset: Vector2 = (rect.size - Vector2(VIEWBOX, VIEWBOX) * scale_factor) * 0.5
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
			Vector2(i * scale_factor + offset.x, (VIEWBOX) * scale_factor + offset.y),
			col, w)
		draw_line(
			Vector2(offset.x, i * scale_factor + offset.y),
			Vector2((VIEWBOX) * scale_factor + offset.x, i * scale_factor + offset.y),
			col, w)
		i += step

	var p_tl := Vector2(offset.x, offset.y)
	var p_tr := Vector2(VIEWBOX * scale_factor + offset.x, offset.y)
	var p_br := Vector2(VIEWBOX * scale_factor + offset.x, VIEWBOX * scale_factor + offset.y)
	var p_bl := Vector2(offset.x, VIEWBOX * scale_factor + offset.y)
	draw_line(p_tl, p_tr, outline_col, 2.0)
	draw_line(p_tr, p_br, outline_col, 2.0)
	draw_line(p_br, p_bl, outline_col, 2.0)
	draw_line(p_bl, p_tl, outline_col, 2.0)

func _draw_segments(rect: Rect2) -> void:
	for seg: DrawSegment in _segments:
		match seg.type:
			"L":
				if seg.points.size() >= 1:
					var scaled_w: float = seg.width * min(rect.size.x, rect.size.y) / VIEWBOX
					draw_line(_viewbox_to_screen(Vector2.ZERO, rect), _viewbox_to_screen(seg.points[0], rect), seg.color, scaled_w)
			"Q":
				if seg.points.size() >= 2:
					var scaled_w: float = seg.width * min(rect.size.x, rect.size.y) / VIEWBOX
					_draw_bezier(rect, Vector2.ZERO, seg.points[0], seg.points[1], seg.color, scaled_w)
			"M":
				if seg.points.size() >= 1:
					var scaled_w: float = seg.width * min(rect.size.x, rect.size.y) / VIEWBOX
					draw_circle(_viewbox_to_screen(seg.points[0], rect), scaled_w * 0.6, seg.color)

	if _drawing:
		var scaled_w: float = _current_width * min(rect.size.x, rect.size.y) / VIEWBOX
		match _current_tool:
			Tool.LINE:
				var start_screen: Vector2 = _viewbox_to_screen(_draw_start, rect)
				var cur_screen: Vector2 = _viewbox_to_screen(_screen_to_viewbox(get_global_mouse_position(), rect), rect)
				draw_line(start_screen, cur_screen, _current_color, scaled_w)
			Tool.CURVE:
				if _curve_step == 1:
					var p0s := _viewbox_to_screen(_curve_p0, rect)
					var p1s := _viewbox_to_screen(_curve_p1, rect)
					var cur := _screen_to_viewbox(get_global_mouse_position(), rect)
					var p2s := _viewbox_to_screen(cur, rect)
					draw_line(p0s, p1s, _current_color, scaled_w)
					var faded_col := Color(_current_color.r, _current_color.g, _current_color.b, 0.4)
					draw_line(p1s, p2s, faded_col, scaled_w * 0.5)
					draw_circle(p0s, scaled_w, _current_color)
					draw_circle(p1s, scaled_w, Color(1.0, 0.8, 0.0))
					_draw_bezier(rect, _curve_p0, _curve_p1, cur, _current_color, scaled_w)

func _draw_bezier(rect: Rect2, p0: Vector2, p1: Vector2, p2: Vector2, col: Color, w: float) -> void:
	var prev: Vector2 = _viewbox_to_screen(p0, rect)
	var steps: int = 20
	for k: int in range(1, steps + 1):
		var t: float = float(k) / float(steps)
		var mt: float = 1.0 - t
		var pt := Vector2(
			mt * mt * p0.x + 2.0 * mt * t * p1.x + t * t * p2.x,
			mt * mt * p0.y + 2.0 * mt * t * p1.y + t * t * p2.y
		)
		var cur: Vector2 = _viewbox_to_screen(pt, rect)
		draw_line(prev, cur, col, w)
		prev = cur

func _draw_preview(rect: Rect2) -> void:
	var scale_factor: float = min(rect.size.x, rect.size.y) / VIEWBOX
	var offset: Vector2 = (rect.size - Vector2(VIEWBOX, VIEWBOX) * scale_factor) * 0.5

	draw_rect(rect, Color(0.0, 0.0, 0.0, 1.0))

	if _selected_icon_id.is_empty():
		return

	var entry: ShipIconGenerator.IconEntry = ShipIconGenerator.get_entry(_selected_category, _selected_icon_id)
	if entry == null:
		return

	draw_set_transform(Vector2(rect.position.x + offset.x, rect.position.y + offset.y), 0.0, Vector2(scale_factor, -scale_factor))

	var path: Array = entry.path
	var last_pt := Vector2.ZERO
	var sub_path: Array = []
	var col := Color(0.066, 0.066, 0.067, 1.0)
	var lw: float = 6.0

	for cmd: Array in path:
		if cmd.is_empty():
			continue
		var t: String = cmd[0]
		match t:
			"M":
				last_pt = Vector2(cmd[1], cmd[2])
				sub_path.append(last_pt)
			"L":
				draw_line(last_pt, Vector2(cmd[1], cmd[2]), col, lw, true)
				last_pt = Vector2(cmd[1], cmd[2])
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
						draw_line(last_pt, pt, col, lw, true)
						last_pt = pt
					sub_path.append(last_pt)
			"Z":
				if not sub_path.is_empty():
					draw_line(last_pt, sub_path[0], col, lw, true)
					last_pt = sub_path[0]

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
