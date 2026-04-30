extends Control

const EquipmentData = preload("res://resources/equipment_data.gd")
const ShipData = preload("res://resources/ship_data.gd")

var detail_title: Label
var detail_name: Label
var detail_type: Label
var detail_stats: Label
var detail_status: Label
var equip_btn: Button
var sell_btn: Button
var unequip_btn: Button
var back_btn: Button
var ship_info_label: Label
var equipped_grid: GridContainer
var inventory_grid: GridContainer

var selected_item: Dictionary = {}
var _selected_equipped: bool = false
var _initialized: bool = false

func _ready() -> void:
	visible = false
	call_deferred("_deferred_init")

func _deferred_init() -> void:
	ship_info_label = find_child("ShipInfoBar", true, false)
	equipped_grid = find_child("EquippedGrid", true, false)
	inventory_grid = find_child("InventoryGrid", true, false)
	detail_title = find_child("DetailTitle", true, false)
	detail_name = find_child("DetailName", true, false)
	detail_type = find_child("DetailType", true, false)
	detail_stats = find_child("DetailStats", true, false)
	detail_status = find_child("DetailStatus", true, false)
	equip_btn = find_child("EquipBtn", true, false)
	sell_btn = find_child("SellBtn", true, false)
	unequip_btn = find_child("UnequipBtn", true, false)
	back_btn = find_child("BackBtn", true, false)

	if equip_btn:
		equip_btn.pressed.connect(_on_equip)
	if sell_btn:
		sell_btn.pressed.connect(_on_sell)
	if unequip_btn:
		unequip_btn.pressed.connect(_on_unequip)
	if back_btn:
		back_btn.pressed.connect(_on_back)

	_build_all()
	_initialized = true

func _build_all() -> void:
	_build_ship_info_bar()
	_build_equipped_list()
	_build_inventory()

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

func _build_equipped_list() -> void:
	if not equipped_grid:
		return
	for child in equipped_grid.get_children():
		child.queue_free()

	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE
	var equipped_weapons = GameState.equipped_weapons.get(ship_id, [])
	var equipped_armor = GameState.equipped_armor.get(ship_id, {})

	var has_anything = false

	if equipped_weapons is Array:
		for w in equipped_weapons:
			if w is Dictionary:
				has_anything = true
				var btn = _make_item_btn(w, true)
				equipped_grid.add_child(btn)

	if equipped_armor is Dictionary and not equipped_armor.is_empty():
		has_anything = true
		var btn = _make_item_btn(equipped_armor, true)
		equipped_grid.add_child(btn)

	if not has_anything:
		var empty_lbl = Label.new()
		empty_lbl.text = "(无已装备装备)"
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		equipped_grid.add_child(empty_lbl)

func _build_inventory() -> void:
	if not inventory_grid:
		return
	for child in inventory_grid.get_children():
		child.queue_free()

	if GameState.equipment_inventory.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "(仓库为空)"
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		inventory_grid.add_child(empty_lbl)
		return

	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE
	var equipped_ids: Array = []
	var equipped_weapons = GameState.equipped_weapons.get(ship_id, [])
	if equipped_weapons is Array:
		for w in equipped_weapons:
			if w is Dictionary:
				equipped_ids.append(w.get("equip_id", ""))
	var equipped_armor = GameState.equipped_armor.get(ship_id, {})
	if equipped_armor is Dictionary and not equipped_armor.is_empty():
		equipped_ids.append(equipped_armor.get("equip_id", ""))

	var has_any = false
	for item in GameState.equipment_inventory:
		var equip_id = item.get("equip_id", "")
		if equipped_ids.has(equip_id):
			continue
		has_any = true
		var btn = _make_item_btn(item, false)
		inventory_grid.add_child(btn)

	if not has_any:
		var empty_lbl = Label.new()
		empty_lbl.text = "(无库存物品)"
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		inventory_grid.add_child(empty_lbl)

func _make_item_btn(item: Dictionary, is_equipped: bool) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 80)
	var quality = item.get("quality", 0)
	var color = EquipmentData.get_quality_color(quality)
	var name_short = item.get("name", "?")
	if name_short.length() > 6:
		name_short = name_short.substr(0, 6)
	var prefix = "[装]" if is_equipped else "[仓]"
	btn.text = "%s\n%s" % [prefix, name_short]
	btn.add_theme_color_override("font_color", color)
	btn.pressed.connect(_on_item_selected.bind(item, is_equipped))
	return btn

func _on_item_selected(item: Dictionary, from_equipped: bool) -> void:
	selected_item = item
	_selected_equipped = from_equipped
	_update_detail_panel()

func _update_detail_panel() -> void:
	if not _initialized:
		return
	if selected_item.is_empty():
		if detail_title: detail_title.text = "选择装备查看详情"
		if detail_name: detail_name.text = ""
		if detail_type: detail_type.text = ""
		if detail_stats: detail_stats.text = ""
		if detail_status: detail_status.text = ""
		if equip_btn: equip_btn.disabled = true
		if sell_btn: sell_btn.disabled = true
		if unequip_btn: unequip_btn.disabled = true
		return

	var quality = selected_item.get("quality", 0)
	var color = EquipmentData.get_quality_color(quality)
	if detail_name:
		detail_name.text = selected_item.get("name", "?")
		detail_name.add_theme_color_override("font_color", color)

	var equip_type_val = selected_item.get("equip_type", "")
	var type_str = "武器"
	if typeof(equip_type_val) == TYPE_STRING:
		if equip_type_val.to_upper() == "ARMOR":
			type_str = "防御"
		else:
			type_str = "武器"
	if detail_type:
		detail_type.text = "类型: " + type_str

	var base_dmg = selected_item.get("base_damage", 0.0)
	var shield_bonus = selected_item.get("shield_bonus", 0.0)
	var shield_regen = selected_item.get("shield_regen_bonus", 0.0)
	if detail_stats:
		if base_dmg > 0:
			detail_stats.text = "基础伤害: %.1f" % base_dmg
		elif shield_bonus > 0:
			detail_stats.text = "护盾上限 +%.0f" % shield_bonus
		elif shield_regen > 0:
			detail_stats.text = "护盾回充 +%.0f/秒" % shield_regen
		else:
			detail_stats.text = ""

	if detail_status:
		if _selected_equipped:
			detail_status.text = "[ 装备中 ]"
			detail_status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		else:
			detail_status.text = "[ 库存 ]"
			detail_status.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	if unequip_btn:
		unequip_btn.disabled = not _selected_equipped
	if equip_btn:
		equip_btn.disabled = _selected_equipped
	if sell_btn:
		sell_btn.disabled = false

func _calc_sell_price(item: Dictionary) -> int:
	if item.has("star_coin_price"):
		return int(item.get("star_coin_price", 0) * 0.4)
	return int(item.get("base_damage", 10) * 5)

func _get_ship_slot_counts() -> Dictionary:
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE
	var ship = ShipData.get_ship(ship_id)
	var w_max = ship.upgraded_weapon_slots if GameState.upgraded_ships.get(ship_id, false) else ship.weapon_slot_count if ship else 1
	var a_max = ship.upgraded_armor_slots if GameState.upgraded_ships.get(ship_id, false) else ship.armor_slot_count if ship else 1
	return {"weapon": w_max, "armor": a_max}

func _on_equip() -> void:
	if selected_item.is_empty() or _selected_equipped:
		return
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE
	var equip_type_val = selected_item.get("equip_type", "")
	var is_armor = false
	if typeof(equip_type_val) == TYPE_STRING:
		is_armor = equip_type_val.to_upper() == "ARMOR"

	if is_armor:
		var slots = _get_ship_slot_counts()
		if slots["armor"] <= 0:
			_show_slot_full()
			return
		GameState.equipped_armor[ship_id] = selected_item.duplicate(true)
	else:
		var slots = _get_ship_slot_counts()
		var equipped_list: Array = GameState.equipped_weapons.get(ship_id, [])
		if not (equipped_list is Array):
			equipped_list = []
		if equipped_list.size() >= slots["weapon"]:
			_show_slot_full()
			return
		equipped_list.append(selected_item.duplicate(true))
		GameState.equipped_weapons[ship_id] = equipped_list

	_build_all()
	_update_detail_panel()

func _on_unequip() -> void:
	if selected_item.is_empty() or not _selected_equipped:
		return
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE
	var equip_type_val = selected_item.get("equip_type", "")
	var is_armor = false
	if typeof(equip_type_val) == TYPE_STRING:
		is_armor = equip_type_val.to_upper() == "ARMOR"

	if is_armor:
		GameState.equipped_armor.erase(ship_id)
		GameState.equipment_inventory.append(selected_item.duplicate(true))
	else:
		var equipped_list: Array = GameState.equipped_weapons.get(ship_id, [])
		if equipped_list is Array:
			var equip_id = selected_item.get("equip_id", "")
			for i in range(equipped_list.size()):
				var w = equipped_list[i]
				if w is Dictionary and w.get("equip_id", "") == equip_id:
					equipped_list.remove_at(i)
					break
			GameState.equipped_weapons[ship_id] = equipped_list
		GameState.equipment_inventory.append(selected_item.duplicate(true))

	selected_item = {}
	_selected_equipped = false
	_build_all()
	_update_detail_panel()

func _show_slot_full() -> void:
	if detail_status:
		detail_status.text = "[ 槽位已满 ]"
		detail_status.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

func _on_sell() -> void:
	if selected_item.is_empty():
		return
	var sell_price = _calc_sell_price(selected_item)
	GameState.star_coin += sell_price
	GameState.equipment_inventory.erase(selected_item)
	selected_item = {}
	_selected_equipped = false
	_build_all()
	_update_detail_panel()

func _on_back() -> void:
	get_parent().close_all_panels()
