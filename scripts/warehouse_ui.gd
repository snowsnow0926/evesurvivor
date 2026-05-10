extends Control

const EquipmentData = preload("res://resources/equipment_data.gd")
const ShipData = preload("res://resources/ship_data.gd")
const WeaponData = preload("res://resources/weapon_data.gd")

var equip_btn: Button
var unequip_btn: Button
var sell_btn: Button
var back_btn: Button
var ship_info_label: Label
var equipped_weapons_grid: HBoxContainer
var equipped_armor_grid: HBoxContainer
var inventory_grid: GridContainer

var selected_item: Dictionary = {}
var _selected_equip_id: String = ""
var _selected_equipped: bool = false
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
	if back_btn:
		back_btn.pressed.connect(_on_back)

	_build_all()
	_initialized = true

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
	ship_info_label.text = "%s | 武器槽: %d | 防御槽: %d" % [ship_name, w_max, a_max]

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
	_update_button_states()
	_update_detail_panel()

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
	if selected_item.is_empty() or _selected_equipped:
		return
	if not _can_equip(selected_item):
		_show_tonnage_warning()
		return

	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE

	var equip_id = selected_item.get("equip_id", "")

	var equip_type_val = selected_item.get("equip_type", "")
	var is_armor = false
	if typeof(equip_type_val) == TYPE_STRING:
		if not equip_type_val.is_empty():
			is_armor = equip_type_val.to_upper() == "ARMOR"
		else:
			is_armor = selected_item.get("type", "").to_upper() == "ARMOR"

	var inventory_item: Dictionary = {}
	for item in GameState.equipment_inventory:
		if item.get("equip_id", "") == equip_id:
			inventory_item = item
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
	if selected_item.is_empty() or not _selected_equipped:
		return
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE

	var equip_id = _selected_equip_id

	var equip_type_val = selected_item.get("equip_type", "")
	var is_armor = false
	if typeof(equip_type_val) == TYPE_STRING:
		if not equip_type_val.is_empty():
			is_armor = equip_type_val.to_upper() == "ARMOR"
		else:
			is_armor = selected_item.get("type", "").to_upper() == "ARMOR"

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
			GameState.equipment_inventory.append(selected_item.duplicate(true))
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
			GameState.equipment_inventory.append(selected_item.duplicate(true))

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

func _on_back() -> void:
	get_parent().close_all_panels()
