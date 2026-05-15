extends Control

signal upgrade_selected(upgrade_id: String)

const WeaponData = preload("res://resources/weapon_data.gd")

var game_manager: Node2D
var upgrade_options: Array = []
var selected_index: int = 0

const _QUALITY_COLORS: Array[Color] = [
	Color(0.75, 0.75, 0.75),
	Color(0.25, 0.85, 0.35),
	Color(0.25, 0.55, 0.95),
	Color(0.80, 0.30, 0.95),
	Color(1.00, 0.60, 0.10),
	Color(1.00, 0.85, 0.20),
]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	_card_panels = [
		$CenterContainer/UpgradePanel/VBox/CardContainer/Card1,
		$CenterContainer/UpgradePanel/VBox/CardContainer/Card2,
		$CenterContainer/UpgradePanel/VBox/CardContainer/Card3,
	]

var _card_panels: Array = []

func move_selection(dir: int) -> void:
	if _card_panels.is_empty():
		return
	selected_index = wrapi(selected_index + dir, 0, _card_panels.size())
	_update_selection()

func confirm_selection() -> void:
	if selected_index >= 0 and selected_index < upgrade_options.size():
		var opt = upgrade_options[selected_index]
		_on_upgrade_selected(opt["id"])

func handle_click(pos: Vector2) -> void:
	for i in range(_card_panels.size()):
		var card = _card_panels[i]
		if card.get_global_rect().has_point(pos):
			selected_index = i
			_update_selection()
			confirm_selection()
			return

func open_upgrade_menu(_available_upgrades: Array, gm: Node2D) -> void:
	game_manager = gm
	var core_id = CoreEquipManager.get_equipped_core_id()
	var candidates = CoreEquipManager.get_available_upgrades(core_id)
	upgrade_options = _pick_random_upgrades(candidates, 3)
	_populate()

	visible = true
	z_index = 100
	selected_index = 0
	_update_selection()

	await get_tree().create_timer(0.1).timeout


func _filter_by_equipped_weapon(pool: Array, gm: Node2D) -> Array:
	return pool

func _pick_random_upgrades(pool: Array, count: int) -> Array:
	# pool 来自 CoreEquipManager.get_available_upgrades()，格式为 {id, name, desc, color, current_level, max_level}
	var available = pool.filter(func(u):
		var current = u.get("current_level", 0)
		var max_lvl = u.get("max_level", 6)
		return current < max_lvl
	)
	var result: Array = []
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	while result.size() < count:
		if available.is_empty():
			break
		var weights = []
		for u in available:
			var w = _get_upgrade_weight(u["id"])
			weights.append(w)
		var total_weight = 0.0
		for w in weights:
			total_weight += w
		var roll = rng.randf_range(0.0, total_weight)
		var acc = 0.0
		var chosen_idx = 0
		for j in range(weights.size()):
			acc += weights[j]
			if roll <= acc:
				chosen_idx = j
				break
		result.append(available[chosen_idx])
		available.remove_at(chosen_idx)

	return result

func _get_upgrade_weight(upgrade_id: String) -> float:
	match upgrade_id:
		"damage":          return 8.0
		"shield_max":      return 2.0
		"fire_coverage":   return 8.0
		"shield_regen":    return 2.0
		"silent_hunter":   return 4.0
		"precision_kill":  return 4.0
		"cannon_bloodthirst": return 8.0
		"cannon_rush":     return 4.0
		"cannon_vengeance":return 4.0
		"railgun_multi":   return 8.0
		"railgun_crit":    return 4.0
		"railgun_damage":  return 4.0
		"laser_duration":  return 8.0
		"laser_width":     return 4.0
		"laser_shield":    return 4.0
	return 3.0

func _populate() -> void:
	for card in _card_panels:
		for child in card.get_children():
			child.queue_free()

	for i in range(mini(upgrade_options.size(), _card_panels.size())):
		var upgrade = upgrade_options[i]
		var card = _card_panels[i]
		_build_card(card, upgrade, i)

func _build_card(card: PanelContainer, upgrade: Dictionary, index: int) -> void:
	var quality_color = upgrade.get("color", Color.WHITE)
	var qc = _QUALITY_COLORS[clampi(upgrade.get("quality", 0), 0, _QUALITY_COLORS.size() - 1)]
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.15, 0.92)
	style.set_border_width_all(3)
	style.border_color = qc
	style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", style)
	card.set_meta("index", index)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(114, 234)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	var name_lbl = Label.new()
	name_lbl.text = upgrade.get("name", "?")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", qc)
	name_lbl.custom_minimum_size.y = 36
	vbox.add_child(name_lbl)

	var level_lbl = Label.new()
	var cur_lvl = upgrade.get("current_level", 0)
	var max_lvl = upgrade.get("max_level", 6)
	level_lbl.text = "Lv.%d/%d" % [cur_lvl + 1, max_lvl]
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_lbl.add_theme_font_size_override("font_size", 12)
	level_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(level_lbl)

	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 2)
	vbox.add_child(sep)

	var desc_lbl = Label.new()
	desc_lbl.text = upgrade.get("desc", "")
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	desc_lbl.custom_minimum_size.y = 140
	vbox.add_child(desc_lbl)

	var key_lbl = Label.new()
	key_lbl.text = "[ %d ]" % (index + 1)
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_lbl.add_theme_font_size_override("font_size", 16)
	key_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	vbox.add_child(key_lbl)

	var btn = Button.new()
	btn.flat = true
	btn.custom_minimum_size = Vector2(114, 234)
	btn.pressed.connect(_on_card_selected.bind(upgrade["id"]))
	btn.gui_input.connect(_on_card_input.bind(upgrade["id"], index))
	card.add_child(btn)

func _on_card_selected(upgrade_id: String) -> void:
	if not visible:
		return
	visible = false
	upgrade_selected.emit(upgrade_id)

func _on_card_input(event: InputEvent, upgrade_id: String, index: int) -> void:
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			selected_index = index
			_update_selection()
	elif event is InputEventMouseMotion:
		var mouse_pos = get_global_mouse_position()
		for i in range(_card_panels.size()):
			if _card_panels[i].get_global_rect().has_point(mouse_pos):
				if selected_index != i:
					selected_index = i
					_update_selection()
				break

func _on_upgrade_selected(upgrade_id: String) -> void:
	SoundManager.play_sfx("upgrade_select")
	visible = false
	upgrade_selected.emit(upgrade_id)

func skip_upgrade() -> void:
	visible = false
	if game_manager and is_instance_valid(game_manager):
		game_manager.is_upgrading = false
		game_manager.is_paused = false
		get_tree().paused = false

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_up"):
		move_selection(-1)
	elif event.is_action_pressed("ui_down"):
		move_selection(1)
	elif event.is_action_pressed("ui_accept"):
		confirm_selection()
	elif event.is_action_pressed("ui_cancel"):
		skip_upgrade()

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			handle_click(get_global_mouse_position())

func _update_selection() -> void:
	for i in range(_card_panels.size()):
		var card = _card_panels[i]
		var is_selected = (i == selected_index)
		var style: StyleBoxFlat = card.get_theme_stylebox("panel") as StyleBoxFlat
		if style == null:
			style = StyleBoxFlat.new()
		if is_selected:
			style.border_color = Color(1.0, 0.9, 0.3)
			style.bg_color = Color(0.1, 0.1, 0.25, 0.96)
		else:
			var qc = _QUALITY_COLORS[0]
			if i < upgrade_options.size():
				qc = _QUALITY_COLORS[clampi(upgrade_options[i].get("quality", 0), 0, _QUALITY_COLORS.size() - 1)]
			style.border_color = qc
			style.bg_color = Color(0.05, 0.05, 0.15, 0.92)
		card.add_theme_stylebox_override("panel", style)
