extends Control

signal upgrade_selected(upgrade_id: String)

const WeaponData = preload("res://resources/weapon_data.gd")

var game_manager: Node2D
var upgrade_options: Array = []
var buttons: Array = []
var selected_index: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[UpgradeMenu] _ready called, process_mode set to ALWAYS")
	set_process_input(true)

func move_selection(dir: int) -> void:
	if buttons.is_empty():
		return
	selected_index = wrapi(selected_index + dir, 0, buttons.size())
	print("[UpgradeMenu] move_selection: dir=", dir, " new_index=", selected_index)
	_update_selection()

func confirm_selection() -> void:
	print("[UpgradeMenu] confirm_selection: index=", selected_index)
	if selected_index >= 0 and selected_index < buttons.size():
		var btn = buttons[selected_index]
		var id = btn.get_meta("upgrade_id")
		print("[UpgradeMenu] Confirming: ", id)
		_on_upgrade_selected(id)
	else:
		print("[UpgradeMenu] Invalid selection!")

func handle_click(pos: Vector2) -> void:
	print("[UpgradeMenu] === HANDLE_CLICK ===")
	print("[UpgradeMenu] Click position (global): ", pos)
	print("[UpgradeMenu] UpgradeMenu visible: ", visible)
	print("[UpgradeMenu] UpgradeMenu rect: ", get_global_rect())
	print("[UpgradeMenu] Buttons count: ", buttons.size())

	for i in range(buttons.size()):
		var btn = buttons[i]
		var rect = btn.get_global_rect()
		var contains = rect.has_point(pos)
		print("[UpgradeMenu] Button[", i, "]")
		print("  - name: '", btn.text.split("\n")[0], "'")
		print("  - rect: ", rect)
		print("  - rect position: min=", rect.position, " max=", rect.end)
		print("  - contains click: ", contains)

		if contains:
			selected_index = i
			_update_selection()
			confirm_selection()
			return

	print("[UpgradeMenu] No button hit!")

func open_upgrade_menu(available_upgrades: Array, gm: Node2D) -> void:
	game_manager = gm
	var filtered_pool = _filter_by_equipped_weapon(available_upgrades, gm)
	upgrade_options = _pick_random_upgrades(filtered_pool, 3)
	_populate()

	visible = true

	selected_index = 0
	_update_selection()
	print("[UpgradeMenu] menu opened")

	await get_tree().create_timer(0.1).timeout
	print("[UpgradeMenu] 0.1s later: visible=", visible)

func _filter_by_equipped_weapon(pool: Array, gm: Node2D) -> Array:
	var weapon_upgrade_ids: Array = []
	var equipped_types = _get_all_equipped_weapon_types(gm)

	for wtype in equipped_types:
		match wtype:
			WeaponData.WeaponID.MISSILE, WeaponData.WeaponID.SMALL_MISSILE:
				if not weapon_upgrade_ids.has("fire_coverage"): weapon_upgrade_ids.append("fire_coverage")
				if not weapon_upgrade_ids.has("silent_hunter"): weapon_upgrade_ids.append("silent_hunter")
				if not weapon_upgrade_ids.has("precision_kill"): weapon_upgrade_ids.append("precision_kill")
			WeaponData.WeaponID.CANNON, WeaponData.WeaponID.SMALL_CANNON:
				if not weapon_upgrade_ids.has("cannon_bloodthirst"): weapon_upgrade_ids.append("cannon_bloodthirst")
				if not weapon_upgrade_ids.has("cannon_rush"): weapon_upgrade_ids.append("cannon_rush")
				if not weapon_upgrade_ids.has("cannon_vengeance"): weapon_upgrade_ids.append("cannon_vengeance")
			WeaponData.WeaponID.RAILGUN, WeaponData.WeaponID.SMALL_RAILGUN:
				if not weapon_upgrade_ids.has("railgun_damage"): weapon_upgrade_ids.append("railgun_damage")
				if not weapon_upgrade_ids.has("railgun_crit"): weapon_upgrade_ids.append("railgun_crit")
				if not weapon_upgrade_ids.has("railgun_multi"): weapon_upgrade_ids.append("railgun_multi")
			WeaponData.WeaponID.LASER, WeaponData.WeaponID.SMALL_LASER:
				if not weapon_upgrade_ids.has("laser_duration"): weapon_upgrade_ids.append("laser_duration")
				if not weapon_upgrade_ids.has("laser_width"): weapon_upgrade_ids.append("laser_width")
				if not weapon_upgrade_ids.has("laser_shield"): weapon_upgrade_ids.append("laser_shield")

	var general_ids = ["damage", "shield_max", "shield_regen"]
	var result: Array = []
	for upgrade in pool:
		if general_ids.has(upgrade["id"]) or weapon_upgrade_ids.has(upgrade["id"]):
			result.append(upgrade)
	return result

func _get_all_equipped_weapon_types(gm: Node2D) -> Array:
	var types: Array = []
	if not gm.player or not is_instance_valid(gm.player):
		return types
	var pw = gm.player.get_primary_weapon()
	if pw:
		types.append(pw.weapon_id)
	var sw = gm.player.get_secondary_weapon()
	if sw:
		types.append(sw.weapon_id)
	return types

func _pick_random_upgrades(pool: Array, count: int) -> Array:
	var available = pool.filter(func(u): return u.get("max", -1) == -1 or game_manager.upgrade_counts.get(u["id"], 0) < u["max"])
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
		"damage":          return 6.0
		"shield_max":      return 4.0
		"fire_coverage":   return 6.0
		"shield_regen":    return 4.0
		"silent_hunter":   return 2.0
		"precision_kill":  return 2.0
		"cannon_bloodthirst": return 4.0
		"cannon_rush":     return 2.0
		"cannon_vengeance":return 2.0
		"railgun_damage":  return 2.0
		"railgun_crit":    return 2.0
		"railgun_multi":    return 2.0
		"laser_duration":  return 4.0
		"laser_width":     return 2.0
		"laser_shield":    return 2.0
	return 3.0

func _populate() -> void:
	for btn in buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	buttons.clear()

	var screen_size = get_viewport().get_visible_rect().size
	var btn_width = 400
	var btn_height = 80
	var btn_spacing = 10
	var start_x = (screen_size.x - btn_width) / 2
	var start_y = (screen_size.y - (upgrade_options.size() * (btn_height + btn_spacing))) / 2

	for i in range(upgrade_options.size()):
		var upgrade = upgrade_options[i]
		var btn = Button.new()
		btn.text = "[ %d ] %s\n%s" % [i + 1, upgrade.get("name", "?"), upgrade.get("desc", "")]
		btn.size = Vector2(btn_width, btn_height)
		btn.position = Vector2(start_x, start_y + i * (btn_height + btn_spacing))
		btn.set_meta("upgrade_id", upgrade["id"])
		btn.set_meta("index", i)

		btn.add_theme_stylebox_override("normal", _make_btn_style(Color(0.15, 0.15, 0.25)))
		btn.add_theme_stylebox_override("hover", _make_btn_style(Color(0.25, 0.35, 0.55)))
		btn.add_theme_stylebox_override("pressed", _make_btn_style(Color(0.1, 0.2, 0.4)))
		btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		btn.add_theme_font_size_override("font_size", 18)

		btn.pressed.connect(_on_btn_pressed.bind(upgrade["id"]))
		add_child(btn)
		buttons.append(btn)
		print("[UpgradeMenu] Added button[", i, "]: ", upgrade.get("name"), " at ", btn.position)

func _on_btn_pressed(upgrade_id: String) -> void:
	if not visible:
		return
	print("[UpgradeMenu] Button pressed: ", upgrade_id)
	visible = false
	upgrade_selected.emit(upgrade_id)
	if game_manager and is_instance_valid(game_manager):
		game_manager.apply_upgrade(upgrade_id)

func _make_btn_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_color = Color(0.4, 0.4, 0.6)
	return style

func _update_selection() -> void:
	for i in range(buttons.size()):
		var btn = buttons[i]
		var is_selected = (i == selected_index)

		if is_selected:
			btn.add_theme_stylebox_override("normal", _make_btn_style(Color(0.3, 0.6, 0.3)))
			btn.add_theme_color_override("font_color", Color(1, 1, 0.3))
			btn.grab_focus()
		else:
			btn.add_theme_stylebox_override("normal", _make_btn_style(Color(0.15, 0.15, 0.25)))
			btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

func _on_upgrade_selected(upgrade_id: String) -> void:
	SoundManager.play_sfx("upgrade_select")
	print("[UpgradeMenu] SELECTED: ", upgrade_id)
	visible = false
	upgrade_selected.emit(upgrade_id)
	if game_manager and is_instance_valid(game_manager):
		game_manager.apply_upgrade(upgrade_id)

func skip_upgrade() -> void:
	print("[UpgradeMenu] SKIP upgrade")
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
	elif event is InputEventMouseMotion:
		var mouse_pos = get_global_mouse_position()
		for i in range(buttons.size()):
			var btn = buttons[i]
			if btn.get_global_rect().has_point(mouse_pos):
				if selected_index != i:
					selected_index = i
					_update_selection()
				break
