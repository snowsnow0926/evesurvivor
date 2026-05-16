extends Control

signal item_equipped

const EquipmentData = preload("res://resources/equipment_data.gd")
const ShipData = preload("res://resources/ship_data.gd")
const WeaponData = preload("res://resources/weapon_data.gd")

var equip_btn: Button
var unequip_btn: Button
var sell_btn: Button
var sell_all_btn: Button
var back_btn: Button
var ship_info_label: Label
var equipped_weapons_grid: HBoxContainer
var equipped_armor_grid: HBoxContainer
var inventory_grid: GridContainer

var selected_item: Dictionary = {}
var _selected_equip_id: String = ""
var _selected_equipped: bool = false
var _selected_core_info: Dictionary = {}
var _initialized: bool = false
var detail_name: Label
var detail_stats: Label
var detail_desc: Label
var detail_icon: Label
var sell_price_label: Label

var equipped_weapons_title: Label
var equipped_armor_title: Label
var inventory_title: Label

func _ready() -> void:
	visible = false
	call_deferred("_deferred_init")

func _deferred_init() -> void:
	ship_info_label = find_child("ShipInfoBar", true, false)
	equipped_weapons_grid = find_child("EquippedWeaponsGrid", true, false)
	equipped_armor_grid = find_child("EquippedArmorGrid", true, false)
	inventory_grid = find_child("InventoryGrid", true, false)
	equip_btn = find_child("EquipBtn", true, false)
	unequip_btn = find_child("UnequipBtn", true, false)
	sell_btn = find_child("SellBtn", true, false)
	sell_all_btn = find_child("SellAllBtn", true, false)
	back_btn = find_child("BackBtn", true, false)
	detail_name = find_child("DetailName", true, false)
	detail_stats = find_child("DetailStats", true, false)
	detail_desc = find_child("DetailDesc", true, false)
	detail_icon = find_child("DetailIcon", true, false)
	sell_price_label = find_child("SellPriceLabel", true, false)
	equipped_weapons_title = find_child("EquippedWeaponsTitle", true, false)
	equipped_armor_title = find_child("EquippedArmorTitle", true, false)
	inventory_title = find_child("InventoryListLabel", true, false)

	if equipped_weapons_title:
		equipped_weapons_title.text = "武器槽"
	if equipped_armor_title:
		equipped_armor_title.text = "防御槽"
	if inventory_title:
		inventory_title.text = "仓库库存"

	if equip_btn:
		equip_btn.pressed.connect(_on_equip)
	if unequip_btn:
		unequip_btn.pressed.connect(_on_unequip)
	if sell_btn:
		sell_btn.pressed.connect(_on_sell)
	if sell_all_btn:
		sell_all_btn.pressed.connect(_on_sell_all)
	if back_btn:
		back_btn.pressed.connect(_on_back)

	_add_core_tab_button()

	_build_all()
	_initialized = true


func _add_core_tab_button() -> void:
	_tab_weapon_btn = find_child("TabWeapon", true, false)
	_tab_core_btn = find_child("TabCore", true, false)
	if _tab_weapon_btn:
		_tab_weapon_btn.pressed.connect(_on_tab_weapon_pressed)
	if _tab_core_btn:
		_tab_core_btn.pressed.connect(_on_tab_core_pressed)

func _build_all() -> void:
	_build_ship_info_bar()
	_update_side_titles()
	_build_equipped_weapons()
	_build_equipped_armor()
	_build_inventory()
	_update_button_states()

func _update_side_titles() -> void:
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE
	var ship = ShipData.get_ship(ship_id)
	var w_max = ship.upgraded_weapon_slots if GameState.upgraded_ships.get(ship_id, false) else ship.weapon_slot_count if ship else 1
	var a_max = ship.upgraded_armor_slots if GameState.upgraded_ships.get(ship_id, false) else ship.armor_slot_count if ship else 1

	var equipped_weapons = GameState.equipped_weapons.get(ship_id, [])
	var equipped_armor_list: Array = GameState.equipped_armor.get(ship_id, [])
	if not (equipped_armor_list is Array):
		equipped_armor_list = []
	var w_count = equipped_weapons.size() if equipped_weapons is Array else 0
	var a_count = equipped_armor_list.size()

	var inv_items: Array = []
	var equipped_ids: Array = []
	if equipped_weapons is Array:
		for w in equipped_weapons:
			if w is Dictionary:
				equipped_ids.append(w.get("equip_id", ""))
	if equipped_armor_list is Array:
		for a in equipped_armor_list:
			if a is Dictionary:
				equipped_ids.append(a.get("equip_id", ""))
	for item in GameState.equipment_inventory:
		if not equipped_ids.has(item.get("equip_id", "")):
			inv_items.append(item)

	if equipped_weapons_title:
		equipped_weapons_title.text = "武器槽 (%d/%d)" % [w_count, w_max]
	if equipped_armor_title:
		equipped_armor_title.text = "防御槽 (%d/%d)" % [a_count, a_max]
	if inventory_title:
		inventory_title.text = "仓库库存 (%d)" % inv_items.size()

func _build_ship_info_bar() -> void:
	if not ship_info_label:
		return
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE
	var ship = ShipData.get_ship(ship_id)
	var ship_name = ship.display_name if ship else "护卫舰"
	var w_max = ship.upgraded_weapon_slots if GameState.upgraded_ships.get(ship_id, false) else ship.weapon_slot_count if ship else 2
	var a_max = ship.upgraded_armor_slots if GameState.upgraded_ships.get(ship_id, false) else ship.armor_slot_count if ship else 1
	ship_info_label.text = "%s | 武器槽: %d | 防御槽: %d | 核心: %s" % [
		ship_name, w_max, a_max,
		CoreEquipManager.get_display_name(CoreEquipManager.get_equipped_core_id()) if not CoreEquipManager.get_equipped_core_id().is_empty() else "未安装",
	]

func _get_ship_slot_counts() -> Dictionary:
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE
	var ship = ShipData.get_ship(ship_id)
	var w_max = ship.upgraded_weapon_slots if GameState.upgraded_ships.get(ship_id, false) else ship.weapon_slot_count if ship else 1
	var a_max = ship.upgraded_armor_slots if GameState.upgraded_ships.get(ship_id, false) else ship.armor_slot_count if ship else 1
	return {"weapon": w_max, "armor": a_max}

func _get_ship_tonnage() -> int:
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE
	var ship = ShipData.get_ship(ship_id)
	return ship.tonnage_tier if ship else EquipmentData.TonnageTier.SMALL

func _can_equip(item: Dictionary) -> bool:
	var equip_tonnage = item.get("tonnage_tier", EquipmentData.TonnageTier.SMALL)
	var ship_tonnage = _get_ship_tonnage()
	return EquipmentData.can_equip_on_ship(ship_tonnage, equip_tonnage)

func _build_equipped_weapons() -> void:
	if not equipped_weapons_grid:
		return

	for child in equipped_weapons_grid.get_children():
		child.queue_free()

	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE

	var slots = _get_ship_slot_counts()
	var w_max = slots["weapon"]

	var equipped_weapons = GameState.equipped_weapons.get(ship_id, [])
	if not (equipped_weapons is Array):
		equipped_weapons = []

	var equipped_count = 0
	for w in equipped_weapons:
		if w is Dictionary:
			var btn = _make_item_btn(w, true, false)
			equipped_weapons_grid.add_child(btn)
			_apply_item_btn_styles(btn, w, true)
			equipped_count += 1

	for i in range(equipped_count, w_max):
		var empty_btn = _make_empty_slot_btn(false)
		equipped_weapons_grid.add_child(empty_btn)

func _build_equipped_armor() -> void:
	if not equipped_armor_grid:
		return

	for child in equipped_armor_grid.get_children():
		child.queue_free()

	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE

	var slots = _get_ship_slot_counts()
	var a_max = slots["armor"]

	var equipped_armor_list: Array = GameState.equipped_armor.get(ship_id, [])
	if not (equipped_armor_list is Array):
		equipped_armor_list = []

	var equipped_count = 0
	for a in equipped_armor_list:
		if a is Dictionary:
			var btn = _make_item_btn(a, true, true)
			equipped_armor_grid.add_child(btn)
			_apply_item_btn_styles(btn, a, true)
			equipped_count += 1

	for i in range(equipped_count, a_max):
		var empty_btn = _make_empty_slot_btn(true)
		equipped_armor_grid.add_child(empty_btn)

func _build_inventory() -> void:
	if not inventory_grid:
		return

	for child in inventory_grid.get_children():
		child.queue_free()

	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE

	var equipped_ids: Array = []
	var equipped_weapons = GameState.equipped_weapons.get(ship_id, [])
	if equipped_weapons is Array:
		for w in equipped_weapons:
			if w is Dictionary:
				equipped_ids.append(w.get("equip_id", ""))
	var equipped_armor_list: Array = GameState.equipped_armor.get(ship_id, [])
	if not (equipped_armor_list is Array):
		equipped_armor_list = []
	if equipped_armor_list is Array:
		for a in equipped_armor_list:
			if a is Dictionary:
				equipped_ids.append(a.get("equip_id", ""))

	var items: Array = []
	for item in GameState.equipment_inventory:
		var equip_id = item.get("equip_id", "")
		if not equipped_ids.has(equip_id):
			items.append(item)

	var _EQUIP_TYPE_ARMOR := "ARMOR"
	var _EQUIP_TYPE_WEAPON := "WEAPON"
	items.sort_custom(func(a, b) -> bool:
		var a_type_val = a.get("equip_type", "")
		var a_is_armor = typeof(a_type_val) == TYPE_STRING and a_type_val.to_upper() == _EQUIP_TYPE_ARMOR
		var b_type_val = b.get("equip_type", "")
		var b_is_armor = typeof(b_type_val) == TYPE_STRING and b_type_val.to_upper() == _EQUIP_TYPE_ARMOR
		if a_is_armor != b_is_armor:
			return not a_is_armor
		var a_quality = a.get("quality", 0)
		var b_quality = b.get("quality", 0)
		if a_quality != b_quality:
			return a_quality > b_quality
		var a_name = _get_item_display_name(a)
		var b_name = _get_item_display_name(b)
		return a_name < b_name
	)

	if items.is_empty():
		var lbl = Label.new()
		lbl.text = "(仓库为空)"
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		inventory_grid.add_child(lbl)
	else:
		for item in items:
			var btn = _make_item_btn(item, false, false)
			inventory_grid.add_child(btn)
			_apply_item_btn_styles(btn, item, false)

func _get_item_display_name(item: Dictionary) -> String:
	var name: String = item.get("name", "")
	if not name.is_empty() and name != "?":
		return name
	var equip_type_val = item.get("equip_type", "")
	var is_armor = false
	if typeof(equip_type_val) == TYPE_STRING and not equip_type_val.is_empty():
		is_armor = equip_type_val.to_upper() == "ARMOR"
	else:
		is_armor = item.get("type", "").to_upper() == "ARMOR"
	if is_armor:
		var aid: int = item.get("armor_id", 0)
		return EquipmentData.get_armor_name(aid)
	else:
		var wid: int = item.get("weapon_id", 0)
		var wd = WeaponData.get_weapon(wid)
		return wd.display_name if wd else "?"

func _make_item_btn(item: Dictionary, is_equipped: bool, is_armor: bool) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 80)

	var quality = item.get("quality", 0)
	var color = EquipmentData.get_quality_color(quality)
	var full_name = _get_item_display_name(item)
	var name_short: String = full_name
	if name_short.length() > 6:
		name_short = name_short.substr(0, 6)
	var prefix = "[装]" if is_equipped else "[仓]"
	btn.text = "%s\n%s" % [prefix, name_short]

	btn.pressed.connect(_on_item_selected.bind(item, is_equipped))
	btn.gui_input.connect(_on_item_btn_input.bind(btn, item, is_equipped))
	return btn

func _make_empty_slot_btn(is_armor: bool) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 80)
	btn.text = "空%s槽" % ("防御" if is_armor else "武器")
	btn.disabled = true
	btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.8)
	style.border_color = Color(0.3, 0.3, 0.3, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.08, 0.08, 0.12, 0.8)
	hover_style.border_color = Color(0.3, 0.3, 0.3, 0.5)
	hover_style.set_border_width_all(1)
	hover_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", hover_style)

	return btn

func _apply_item_btn_styles(btn: Button, item: Dictionary, is_equipped: bool) -> void:
	var quality = item.get("quality", 0)
	var color = EquipmentData.get_quality_color(quality)

	btn.add_theme_color_override("font_color", color)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.25, 0.9)
	style.border_color = color.darkened(0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.2, 0.2, 0.35, 0.95)
	hover_style.border_color = color
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.12, 0.12, 0.2, 0.95)
	pressed_style.border_color = color
	pressed_style.set_border_width_all(2)
	pressed_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	var disabled_style = StyleBoxFlat.new()
	disabled_style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	disabled_style.border_color = Color(0.3, 0.3, 0.3, 0.5)
	disabled_style.set_border_width_all(2)
	disabled_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("disabled", disabled_style)

func _on_item_selected(item: Dictionary, from_equipped: bool) -> void:
	selected_item = item
	_selected_equip_id = item.get("equip_id", "")
	_selected_equipped = from_equipped
	_current_tab = "weapon"  # weapon or defense
	_update_button_states()
	_update_detail_panel()

func _on_item_btn_input(event: InputEvent, btn: Button, item: Dictionary, from_equipped: bool) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and mb.double_click:
			if from_equipped:
				_unequip_item(item, true)
			else:
				_equip_item(item, false)

func _update_button_states() -> void:
	var has_selection = not selected_item.is_empty()
	var can_equip = true
	if has_selection and not _selected_equipped:
		can_equip = _can_equip(selected_item)
	if equip_btn:
		equip_btn.disabled = not has_selection or _selected_equipped or not can_equip
	if unequip_btn:
		unequip_btn.disabled = not has_selection or not _selected_equipped
	if sell_btn:
		sell_btn.disabled = not has_selection

func _on_equip() -> void:
	if _current_tab == TAB_CORE:
		_equip_core_from_tab()
	else:
		_equip_item(selected_item, _selected_equipped)


func _equip_core_from_tab() -> void:
	if _selected_core_info.is_empty():
		return
	var core_id = _selected_core_info["core_id"]
	if CoreEquipManager.equip_core(core_id):
		GameState.auto_save()
		_update_core_content()


func _on_core_equip_selected(core_info: Dictionary) -> void:
	var core_id = core_info["core_id"]
	if CoreEquipManager.equip_core(core_id):
		GameState.auto_save()
		_update_core_content()

func _equip_item(item: Dictionary, from_equipped: bool) -> void:
	if item.is_empty() or from_equipped:
		return
	if not _can_equip(item):
		_show_tonnage_warning()
		return

	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE

	var equip_id = item.get("equip_id", "")

	var equip_type_val = item.get("equip_type", "")
	var is_armor = false
	if typeof(equip_type_val) == TYPE_STRING:
		if not equip_type_val.is_empty():
			is_armor = equip_type_val.to_upper() == "ARMOR"
		else:
			is_armor = item.get("type", "").to_upper() == "ARMOR"

	var inventory_item: Dictionary = {}
	for inv_item in GameState.equipment_inventory:
		if inv_item.get("equip_id", "") == equip_id:
			inventory_item = inv_item
			break

	if inventory_item.is_empty():
		return

	if is_armor:
		var slots = _get_ship_slot_counts()
		var armor_list: Array = GameState.equipped_armor.get(ship_id, [])
		if not (armor_list is Array):
			armor_list = []
		if armor_list.size() >= slots["armor"]:
			return
		armor_list.append(inventory_item.duplicate(true))
		GameState.equipped_armor[ship_id] = armor_list
	else:
		var slots = _get_ship_slot_counts()
		var equipped_list: Array = GameState.equipped_weapons.get(ship_id, [])
		if not (equipped_list is Array):
			equipped_list = []
		if equipped_list.size() >= slots["weapon"]:
			return
		equipped_list.append(inventory_item.duplicate(true))
		GameState.equipped_weapons[ship_id] = equipped_list

	GameState.equipment_inventory.erase(inventory_item)
	selected_item = {}
	_selected_equip_id = ""
	_build_all()
	GameState.auto_save()
	item_equipped.emit()

func _show_tonnage_warning() -> void:
	var tonnage = _get_ship_tonnage()
	var t_name = EquipmentData.get_tonnage_name(tonnage)
	var msg = "当前舰船无法装备此吨位装备\n%s只能装备 %s 及以下吨位装备" % [GameState.selected_ship_id, t_name]
	if has_node("TonnageWarning"):
		var w = find_child("TonnageWarning", true, false)
		if w:
			w.text = msg
			w.visible = true
			return
	print("[WarehouseUI] ", msg)

func _on_unequip() -> void:
	if _current_tab == TAB_CORE:
		_unequip_core_from_tab()
	else:
		_unequip_item(selected_item, _selected_equipped)


func _unequip_core_from_tab() -> void:
	CoreEquipManager.unequip_core()
	GameState.auto_save()
	_update_core_content()

func _unequip_item(item: Dictionary, from_equipped: bool) -> void:
	if item.is_empty() or not from_equipped:
		return
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE

	var equip_id = item.get("equip_id", "")

	var equip_type_val = item.get("equip_type", "")
	var is_armor = false
	if typeof(equip_type_val) == TYPE_STRING:
		if not equip_type_val.is_empty():
			is_armor = equip_type_val.to_upper() == "ARMOR"
		else:
			is_armor = item.get("type", "").to_upper() == "ARMOR"

	if is_armor:
		var armor_list: Array = GameState.equipped_armor.get(ship_id, [])
		if not (armor_list is Array):
			armor_list = []
		for i in range(armor_list.size()):
			var a = armor_list[i]
			if a is Dictionary and a.get("equip_id", "") == equip_id:
				armor_list.remove_at(i)
				break
		GameState.equipped_armor[ship_id] = armor_list
		var already_in_inventory = GameState.equipment_inventory.any(
			func(it): return it.get("equip_id", "") == equip_id)
		if not already_in_inventory:
			GameState.equipment_inventory.append(item.duplicate(true))
	else:
		var equipped_list: Array = GameState.equipped_weapons.get(ship_id, [])
		if equipped_list is Array:
			for i in range(equipped_list.size()):
				var w = equipped_list[i]
				if w is Dictionary and w.get("equip_id", "") == equip_id:
					equipped_list.remove_at(i)
					break
			GameState.equipped_weapons[ship_id] = equipped_list
		var already_in_inventory = GameState.equipment_inventory.any(
			func(it): return it.get("equip_id", "") == equip_id)
		if not already_in_inventory:
			GameState.equipment_inventory.append(item.duplicate(true))

	selected_item = {}
	_selected_equip_id = ""
	_build_all()
	GameState.auto_save()

func _update_detail_panel() -> void:
	if selected_item.is_empty():
		if detail_name:
			detail_name.text = "选择一件装备查看详情"
			detail_name.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		if detail_stats:
			detail_stats.text = ""
		if detail_desc:
			detail_desc.text = ""
		if detail_icon:
			detail_icon.text = "[?]"
		if sell_price_label:
			sell_price_label.text = "出售: --"
		return

	var q = selected_item.get("quality", 0)
	var color = EquipmentData.get_quality_color(q)
	var name = _get_item_display_name(selected_item)
	var equip_type_val = selected_item.get("equip_type", "")
	var is_armor = false
	if typeof(equip_type_val) == TYPE_STRING:
		if not equip_type_val.is_empty():
			is_armor = equip_type_val.to_upper() == "ARMOR"
		else:
			is_armor = selected_item.get("type", "").to_upper() == "ARMOR"

	var icon = "[W]" if not is_armor else "[A]"
	if detail_icon:
		detail_icon.text = icon
		detail_icon.add_theme_color_override("font_color", color)

	if detail_name:
		var prefix = "[已装备] " if _selected_equipped else "[仓库] "
		var tonnage_tier = selected_item.get("tonnage_tier", EquipmentData.TonnageTier.SMALL)
		var t_name = EquipmentData.get_tonnage_name(tonnage_tier)
		var can_eq = _can_equip(selected_item) if not _selected_equipped else true
		var tonnage_hint = " [%s]" % t_name if selected_item.has("tonnage_tier") else ""
		var tonnage_warn = " (不可装备)" if not can_eq else ""
		detail_name.text = prefix + name + tonnage_hint + tonnage_warn
		detail_name.add_theme_color_override("font_color", color)

	var stats_text = ""
	if is_armor:
		var shield = selected_item.get("shield_bonus", 0.0)
		var regen = selected_item.get("shield_regen_bonus", 0.0)
		var hp_regen_val = selected_item.get("hp_regen_bonus", 0.0)
		var lines: Array = []
		if shield > 0:
			lines.append("护盾上限 +%.0f" % shield)
		if regen > 0:
			lines.append("护盾回充 +%.1f/秒" % regen)
		if hp_regen_val > 0:
			lines.append("装甲回复 +%.1f/秒" % hp_regen_val)
		stats_text = "\n".join(lines) if not lines.is_empty() else "无防御加成"
	else:
		var dmg = selected_item.get("base_damage", 0.0)
		var interval = selected_item.get("fire_interval", 1.0)
		var range = selected_item.get("range", 0.0)
		var crit_rate = selected_item.get("crit_rate", 0.0)
		var crit_mult = selected_item.get("crit_mult", 1.5)
		var dps = dmg / interval if interval > 0 else 0.0
		stats_text = "DPS: %.0f | 伤害: %.0f | 射速: %.2f/s | 射程: %.0f\n暴击率: %.0f%% | 暴击倍率: %.1fx" % [
			dps, dmg, 1.0 / interval if interval > 0 else 0, range,
			crit_rate * 100, crit_mult]

	if detail_stats:
		detail_stats.text = stats_text
		detail_stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	var desc = selected_item.get("description", "")
	if detail_desc:
		detail_desc.text = desc
		detail_desc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	var sell_price = _calc_sell_price(selected_item)
	if sell_price_label:
		sell_price_label.text = "出售: %d 星币" % sell_price

func _calc_sell_price(item: Dictionary) -> int:
	if item.has("star_coin_price"):
		return int(item.get("star_coin_price", 0) * 0.4)
	return int(item.get("base_damage", 10) * 5)

func _on_sell() -> void:
	if selected_item.is_empty():
		return
	SoundManager.play_sfx("button_click")
	var sell_price = _calc_sell_price(selected_item)
	GameState.star_coin += sell_price

	var equip_id_to_remove = _selected_equip_id if _selected_equip_id != "" else selected_item.get("equip_id", "")
	var removed = false
	for item in GameState.equipment_inventory:
		if item.get("equip_id", "") == equip_id_to_remove:
			GameState.equipment_inventory.erase(item)
			removed = true
			break

	if not removed:
		GameState.equipment_inventory.erase(selected_item)

	selected_item = {}
	_selected_equip_id = ""
	_update_detail_panel()
	_build_all()
	GameState.auto_save()

func _on_sell_all() -> void:
	SoundManager.play_sfx("button_click")
	_show_sell_all_confirm()

func _show_sell_all_confirm() -> void:
	var unequipped_ids: Array = []
	var equipped_ids: Array = []

	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE

	var eq_weapons = GameState.equipped_weapons.get(ship_id, [])
	if eq_weapons is Array:
		for w in eq_weapons:
			if w is Dictionary:
				equipped_ids.append(w.get("equip_id", ""))
	var eq_armor_list: Array = GameState.equipped_armor.get(ship_id, [])
	if not (eq_armor_list is Array):
		eq_armor_list = []
	if eq_armor_list is Array:
		for a in eq_armor_list:
			if a is Dictionary:
				equipped_ids.append(a.get("equip_id", ""))

	var unequipped_items: Array = []
	for item in GameState.equipment_inventory:
		if not equipped_ids.has(item.get("equip_id", "")):
			unequipped_items.append(item)
			unequipped_ids.append(item.get("equip_id", ""))

	if unequipped_items.is_empty():
		_show_notification("没有可出售的物品")
		return

	var total_price = 0
	for item in unequipped_items:
		total_price += _calc_sell_price(item)

	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "确定要出售全部 %d 件未装备物品吗？\n预计获得: %d 星币" % [unequipped_items.size(), total_price]
	dialog.ok_button_text = "出售"
	dialog.cancel_button_text = "取消"
	get_tree().current_scene.add_child(dialog)
	dialog.confirmed.connect(_do_sell_all.bind(unequipped_ids, total_price))
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()

func _do_sell_all(equip_ids: Array, total_price: int) -> void:
	SoundManager.play_sfx("button_click")
	for equip_id in equip_ids:
		for idx in range(GameState.equipment_inventory.size() - 1, -1, -1):
			if GameState.equipment_inventory[idx].get("equip_id", "") == equip_id:
				GameState.equipment_inventory.remove_at(idx)
				break
	GameState.star_coin += total_price
	selected_item = {}
	_selected_equip_id = ""
	_update_detail_panel()
	_build_all()
	GameState.auto_save()
	_show_notification("已出售 %d 件物品，获得 %d 星币" % [equip_ids.size(), total_price])

func _show_notification(msg: String) -> void:
	var notif = AcceptDialog.new()
	notif.dialog_text = msg
	notif.ok_button_text = "确定"
	var parent_node = get_parent()
	if parent_node:
		parent_node.add_child(notif)
	else:
		add_child(notif)
	notif.popup_centered()
	notif.confirmed.connect(notif.queue_free)

func _on_back() -> void:
	get_parent().close_all_panels()


# ================================================================
# 核心Tab（第三个分页）
# ================================================================

const TAB_CORE: String = "core"

var _current_tab: String = "weapon"  # weapon / defense / core

var _tab_weapon_btn: Button
var _tab_core_btn: Button

func _on_tab_weapon_pressed() -> void:
	_current_tab = "weapon"
	_update_tab_button_styles()
	_build_inventory()


func _on_tab_core_pressed() -> void:
	_current_tab = TAB_CORE
	_update_tab_button_styles()
	_show_core_tab()


func _update_tab_button_styles() -> void:
	if _tab_weapon_btn:
		_tab_weapon_btn.add_theme_stylebox_override("normal",
			_make_tab_style(Color(0.2, 0.3, 0.5) if _current_tab == "weapon" else Color(0.15, 0.15, 0.2)))
	if _tab_core_btn:
		_tab_core_btn.add_theme_stylebox_override("normal",
			_make_tab_style(Color(0.2, 0.3, 0.5) if _current_tab == TAB_CORE else Color(0.15, 0.15, 0.2)))


func _make_tab_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	style.border_color = Color(0.3, 0.4, 0.6)
	return style


func _show_core_tab() -> void:
	_current_tab = TAB_CORE
	_update_core_content()


func _update_core_content() -> void:
	if not inventory_grid:
		return
	for child in inventory_grid.get_children():
		child.queue_free()

	inventory_title.text = "核心仓库"

	var cores = CoreEquipManager.get_all_cores_summary()
	if cores.is_empty():
		var lbl = Label.new()
		lbl.text = "(无可用核心)"
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		inventory_grid.add_child(lbl)
		return

	for core_info in cores:
		var btn = _make_core_btn(core_info)
		inventory_grid.add_child(btn)


func _make_core_btn(core_info: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 80)

	var core_id = core_info["core_id"]
	var display_name = core_info["display_name"]
	var is_unlocked = core_info["is_unlocked"]
	var is_equipped = core_info["is_equipped"]

	var color = Color(0.7, 0.7, 0.7) if is_unlocked else Color(0.3, 0.3, 0.3)
	var prefix = "[装]" if is_equipped else ("[仓]" if is_unlocked else "[锁]")
	var name_short = display_name
	if name_short.length() > 6:
		name_short = name_short.substr(0, 6)
	btn.text = "%s\n%s" % [prefix, name_short]
	btn.add_theme_color_override("font_color", color)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.25, 0.9)
	style.border_color = color.darkened(0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.2, 0.2, 0.35, 0.95)
	hover_style.border_color = color
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.pressed.connect(_on_core_item_selected.bind(core_info))
	return btn


func _on_core_item_selected(core_info: Dictionary) -> void:
	_selected_core_info = core_info
	_update_core_detail(core_info)


func _update_core_detail(core_info: Dictionary) -> void:
	var core_id = core_info["core_id"]

	if detail_name:
		var name = CoreEquipManager.get_display_name(core_id)
		var status = "[已装备]" if core_info["is_equipped"] else ("[仓库]" if core_info["is_unlocked"] else "[未解锁]")
		detail_name.text = "%s %s" % [status, name]
		detail_name.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))

	if detail_icon:
		detail_icon.text = "[C]"
		detail_icon.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))

	var skills = CoreEquipManager.get_core_skill_detail(core_id)
	var stats_text = ""
	for skill in skills:
		var lvl = skill["current_level"]
		var max_lvl = skill["max_level"]
		var prefix_tag = "[种族]" if skill["is_race_skill"] else "[通用]"
		stats_text += "%s %s Lv.%d/%d\n" % [prefix_tag, skill["name"], lvl, max_lvl]

	if detail_stats:
		detail_stats.text = stats_text.strip_edges()
		detail_stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	if detail_desc:
		detail_desc.text = "选择核心进行查看和管理"
		detail_desc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	if sell_price_label:
		sell_price_label.text = ""

	# 按钮状态
	var is_unlocked = core_info["is_unlocked"]
	var is_equipped = core_info["is_equipped"]
	if equip_btn:
		equip_btn.text = "安装"
		equip_btn.disabled = not is_unlocked or is_equipped
	if unequip_btn:
		unequip_btn.text = "拆卸"
		unequip_btn.disabled = not is_equipped
	if sell_btn:
		sell_btn.disabled = true
