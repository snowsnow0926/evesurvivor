class_name ShipIconGenerator
extends RefCounted

const ICON_VIEWBOX: float = 100.0
const ICON_SIZE: float = 80.0

enum Category { SHIP, ENEMY, BUILDING }

class IconEntry:
	var id: String
	var name_zh: String
	var name_en: String
	var path: Array
	var category: Category
	var texture_path: String
	var _texture: Texture2D
	var _tinted: Texture2D
	var _tinted_color: Color

	static func from_dict(d: Dictionary, cat: Category) -> IconEntry:
		var e := IconEntry.new()
		e.id = d.get("id", "")
		e.name_zh = d.get("name_zh", e.id)
		e.name_en = d.get("name_en", e.id)
		e.path = d.get("path", [])
		e.category = cat
		e.texture_path = d.get("texture_path", "")
		return e

	func get_texture(tint_color: Color = Color.WHITE) -> Texture2D:
		if tint_color == Color.WHITE:
			if _texture != null:
				return _texture
		else:
			if _tinted != null and _tinted_color == tint_color:
				return _tinted
		if texture_path.is_empty():
			return null
		var raw: Texture2D = load(texture_path)
		if raw == null:
			return null

		if tint_color == Color.WHITE:
			_texture = raw
			return _texture

		var img: Image = raw.get_image()
		if img == null:
			return raw
		var copy := img.duplicate()
		for y: int in range(copy.get_height()):
			for x: int in range(copy.get_width()):
				var px: Color = copy.get_pixel(x, y)
				if px.v > 0.05:
					copy.set_pixel(x, y, tint_color * px.v)
		_tinted = ImageTexture.create_from_image(copy)
		_tinted_color = tint_color
		return _tinted

static var _data: Dictionary = {
	Category.SHIP: {},
	Category.ENEMY: {},
	Category.BUILDING: {},
}

static var _loaded: bool = false

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_load_from_json()

static func _load_from_json() -> void:
	var path_str := "res://resources/icon_definitions.json"
	var file := FileAccess.open(path_str, FileAccess.READ)
	if file == null:
		push_warning("ShipIconGenerator: 无法加载 %s, 错误: %s" % [path_str, FileAccess.get_open_error()])
		return
	var json_str := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_str) != OK:
		push_warning("ShipIconGenerator: JSON 解析失败")
		return
	var root: Dictionary = json.get_data()
	_data[Category.SHIP] = {}
	_data[Category.ENEMY] = {}
	_data[Category.BUILDING] = {}
	var cat_map := {
		"ships": Category.SHIP,
		"enemies": Category.ENEMY,
		"buildings": Category.BUILDING,
	}
	for cat_key: String in cat_map:
		if not root.has(cat_key):
			continue
		var list: Array = root[cat_key]
		var cat: Category = cat_map[cat_key]
		for entry: Dictionary in list:
			var e := IconEntry.from_dict(entry, cat)
			_data[cat][e.id] = e

static func get_all_entries(category: Category) -> Array:
	_ensure_loaded()
	var result: Array = []
	for e: IconEntry in _data[category].values():
		result.append(e)
	return result

static func get_entry(category: Category, icon_id: String) -> IconEntry:
	_ensure_loaded()
	if _data[category].has(icon_id):
		return _data[category][icon_id]
	return null

static func get_icon_data_by_id(category: Category, icon_id: String) -> Dictionary:
	var e := get_entry(category, icon_id)
	if e == null:
		return {}
	return {
		"id": e.id,
		"name_zh": e.name_zh,
		"name_en": e.name_en,
		"path": e.path,
	}

static func get_icon_data(icon_id: String) -> Dictionary:
	_ensure_loaded()
	for cat: Category in [Category.SHIP, Category.ENEMY, Category.BUILDING]:
		if _data[cat].has(icon_id):
			return get_icon_data_by_id(cat, icon_id)
	return {}

static func get_all_icon_ids(category: Category) -> Array:
	_ensure_loaded()
	return Array(_data[category].keys(), TYPE_STRING, "", null)

static func get_name_zh(icon_id: String) -> String:
	var e := get_entry_by_id(icon_id)
	return e.name_zh if e else icon_id

static func get_name_en(icon_id: String) -> String:
	var e := get_entry_by_id(icon_id)
	return e.name_en if e else icon_id

static func get_entry_by_id(icon_id: String) -> IconEntry:
	_ensure_loaded()
	for cat: Category in [Category.SHIP, Category.ENEMY, Category.BUILDING]:
		if _data[cat].has(icon_id):
			return _data[cat][icon_id]
	return null

static func get_category_by_id(icon_id: String) -> Category:
	var e := get_entry_by_id(icon_id)
	return e.category if e else Category.SHIP

static func get_texture(category: Category, icon_id: String) -> Texture2D:
	var e := get_entry(category, icon_id)
	return e.get_texture() if e else null

static func set_icon_path(icon_id: String, path_data: Array) -> bool:
	var e := get_entry_by_id(icon_id)
	if e == null:
		return false
	e.path = path_data
	return true

static func reload() -> void:
	_loaded = false
	_ensure_loaded()

static func get_icon_for_ship_id(ship_id: int) -> String:
	var ids := get_all_icon_ids(Category.SHIP)
	if ship_id < 0 or ship_id >= ids.size():
		return "frigate"
	return ids[ship_id]

static func build_polygon_from_path(path: Array) -> PackedVector2Array:
	var closed_polygons: Array[PackedVector2Array] = []
	var current_open: Array[Vector2] = []
	var last_pt := Vector2.ZERO
	var sub_start := Vector2.ZERO

	for cmd: Array in path:
		if cmd.is_empty():
			continue
		var t: String = cmd[0]
		match t:
			"M":
				if not current_open.is_empty() and current_open.size() >= 2:
					closed_polygons.append(PackedVector2Array(current_open))
				current_open.clear()
				last_pt = Vector2(cmd[1], cmd[2])
				current_open.append(last_pt)
				sub_start = last_pt
			"L":
				var p: Vector2 = Vector2(cmd[1], cmd[2])
				current_open.append(p)
				last_pt = p
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
						current_open.append(pt)
					last_pt = p2
			"Z":
				if not current_open.is_empty() and current_open.size() >= 2:
					current_open.append(sub_start)

	if not current_open.is_empty() and current_open.size() >= 2:
		closed_polygons.append(PackedVector2Array(current_open))

	if closed_polygons.is_empty():
		return PackedVector2Array()

	var primary := closed_polygons[0]
	var scale_val: float = ICON_SIZE / ICON_VIEWBOX
	var offset := Vector2(-50.0 * scale_val, -50.0 * scale_val)

	var result := PackedVector2Array()
	for p: Vector2 in primary:
		result.append(p * scale_val + offset)
	return result
