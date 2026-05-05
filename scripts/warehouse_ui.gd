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
var detail_compare: Label
var detail_desc: Label
var detail_icon: Label
var sell_price_label: Label

var equipped_weapons_title: Label
var equipped_armor_title: Label
var inventory_title: Label

var weapon_dps_label: Label
var weapon_bonus_label: Label
var armor_hp_label: Label
var armor_shield_label: Label
var ship_hp_label: Label
var ship_slots_label: Label

const _SCENE_TO_WEAPON_TYPE: Dictionary = {
	"res://scenes/Missile.tscn": WeaponData.WeaponID.MISSILE,
	"res://scenes/CannonBullet.tscn": WeaponData.WeaponID.CANNON,
	"res://scenes/RailgunBullet.tscn": WeaponData.WeaponID.RAILGUN,
	"res://scenes/LaserBeam.tscn": WeaponData.WeaponID.LASER,
}

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
	detail_compare = find_child("DetailCompare", true, false)
	detail_desc = find_child("DetailDesc", true, false)
	detail_icon = find_child("DetailIcon", true, false)
	sell_price_label = find_child("SellPriceLabel", true, false)
	equipped_weapons_title = find_child("EquippedWeaponsTitle", true, false)
	equipped_armor_title = find_child("EquippedArmorTitle", true, false)
	inventory_title = find_child("InventoryListLabel", true, false)

	weapon_dps_label = find_child("WeaponDPS", true, false)
	weapon_bonus_label = find_child("WeaponBonus", true, false)
	armor_hp_label = find_child("ArmorHP", true, false)
	armor_shield_label = find_child("ArmorShield", true, false)
	ship_hp_label = find_child("ShipHP", true, false)
	ship_slots_label = find_child("ShipSlots", true, false)

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
	_update_ship_stats_panel()
	_update_side_titles()
	_build_equipped_weapons()
	_build_equipped_armor()
	_build_inventory()
	_update_button_states()

func _get_ship_id() -> int:
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE
	return ship_id

func _get_ship() -> ShipData:
	return ShipData.get_ship(_get_ship_id())

func _get_ship_base_stats() -> Dictionary:
	var ship = _get_ship()
	if not ship:
		return {"hp": 100, "shield": 50}
	return {"hp": ship.base_hp, "shield": ship.base_shield}

func _get_weapon_slot_counts() -> int:
	var ship = _get_ship()
	if not ship:
		return 1
	if GameState.upgraded_ships.get(_get_ship_id(), false):
		return ship.upgraded_weapon_slots
	return ship.weapon_slot_count

func _get_armor_slot_counts() -> int:
	var ship = _get_ship()
	if not ship:
		return 1
	if GameState.upgraded_ships.get(_get_ship_id(), false):
		return ship.upgraded_armor_slots
	return ship.armor_slot_count

func _get_weapon_type_from_dict(item: Dictionary) -> int:
	var scene_path = item.get("scene_path", "res://scenes/Missile.tscn")
	if item.has("shop_item_id"):
		var sid = item.get("shop_item_id")
		var shop_to_weapon_type: Dictionary = {
			0: WeaponData.WeaponID.SMALL_MISSILE,
			1: WeaponData.WeaponID.MEDIUM_MISSILE,
			2: WeaponData.WeaponID.LARGE_MISSILE,
			3: WeaponData.WeaponID.FLAGSHIP_MISSILE,
			4: WeaponData.WeaponID.SMALL_CANNON,
			5: WeaponData.WeaponID.MEDIUM_CANNON,
			6: WeaponData.WeaponID.LARGE_CANNON,
			7: WeaponData.WeaponID.FLAGSHIP_CANNON,
			8: WeaponData.WeaponID.SMALL_RAILGUN,
			9: WeaponData.WeaponID.MEDIUM_RAILGUN,
			10: WeaponData.WeaponID.LARGE_RAILGUN,
			11: WeaponData.WeaponID.FLAGSHIP_RAILGUN,
			12: WeaponData.WeaponID.SMALL_LASER,
			13: WeaponData.WeaponID.MEDIUM_LASER,
			14: WeaponData.WeaponID.LARGE_LASER,
			15: WeaponData.WeaponID.FLAGSHIP_LASER,
		}
		return shop_to_weapon_type.get(sid, _SCENE_TO_WEAPON_TYPE.get(scene_path, WeaponData.WeaponID.MISSILE))
	return _SCENE_TO_WEAPON_TYPE.get(scene_path, WeaponData.WeaponID.MISSILE)

func _get_weapon_stats_from_dict(item: Dictionary) -> Dictionary:
	var dps: float = 0.0
	var dmg: float = item.get("base_damage", 0.0)
	var interval: float = item.get("fire_interval", 1.0)
	var rng: float = item.get("range", 0.0)
	var cr: float = item.get("crit_rate", 0.0)
	var cm: float = item.get("crit_mult", 1.5)
	if interval > 0:
		dps = dmg / interval
	return {
		"dps": dps,
		"damage": dmg,
		"fire_interval": interval,
		"range": rng,
		"crit_rate": cr,
		"crit_mult": cm,
		"display_name": item.get("name", "?"),
	}

func _get_total_weapon_stats() -> Dictionary:
	var sid = _get_ship_id()
	var equipped: Array = GameState.equipped_weapons.get(sid, [])
	if not (equipped is Array):
		equipped = []

	if equipped.is_empty():
		var default_wd = WeaponData.get_weapon(WeaponData.WeaponID.MISSILE)
		return {
			"dps": default_wd.damage / default_wd.fire_interval if default_wd.fire_interval > 0 else 0.0,
			"damage": default_wd.damage,
			"fire_interval": default_wd.fire_interval,
			"range": default_wd.range,
			"crit_rate": default_wd.crit_rate,
			"crit_mult": default_wd.crit_mult,
			"count": 0,
		}

	var total_dps: float = 0.0
	var total_damage: float = 0.0
	var total_range: float = 0.0
	var avg_crit_rate: float = 0.0
	var avg_crit_mult: float = 0.0
	var fire_intervals: Array = []

	for w in equipped:
		if not (w is Dictionary):
			continue
		var stats = _get_weapon_stats_from_dict(w)
		total_dps += stats["dps"]
		total_damage += stats["damage"]
		fire_intervals.append(stats["fire_interval"])
		total_range = maxf(total_range, stats["range"])
		avg_crit_rate += stats["crit_rate"]
		avg_crit_mult += stats["crit_mult"]

	var count = float(equipped.size())
	return {
		"dps": total_dps,
		"damage": total_damage,
		"fire_interval": 0.0,
		"range": total_range,
		"crit_rate": avg_crit_rate / count if count > 0 else 0.0,
		"crit_mult": avg_crit_mult / count if count > 0 else 1.5,
		"fire_intervals": fire_intervals,
		"count": count,
	}

func _get_total_armor_stats() -> Dictionary:
	var sid = _get_ship_id()
	var base = _get_ship_base_stats()
	var armor_list: Array = GameState.equipped_armor.get(sid, [])
	if not (armor_list is Array):
		armor_list = []

	var shield_bonus: float = 0.0
	var regen_bonus: float = 0.0
	for a in armor_list:
		if not (a is Dictionary):
			continue
		shield_bonus += a.get("shield_bonus", 0.0)
		regen_bonus += a.get("shield_regen_bonus", 0.0)

	return {
		"hp": base["hp"],
		"shield_base": base["shield"],
		"shield_total": base["shield"] + shield_bonus,
		"shield_bonus": shield_bonus,
		"regen_base": 4.0,
		"regen_total": 4.0 + regen_bonus,
		"regen_bonus": regen_bonus,
	}

func _update_ship_stats_panel() -> void:
	var w_stats = _get_total_weapon_stats()
	var a_stats = _get_total_armor_stats()

	if weapon_dps_label:
		if w_stats["count"] > 0:
			weapon_dps_label.text = "DPS: %.0f  伤害: %.0f  射程: %.0f" % [
				w_stats["dps"], w_stats["damage"], w_stats["range"]]
			weapon_dps_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		else:
			weapon_dps_label.text = "DPS: --  伤害: --  射程: --  (默认武器)"
			weapon_dps_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

	if weapon_bonus_label:
		weapon_bonus_label.text = "暴击率: %.0f%%  暴击倍率: %.1fx" % [w_stats["crit_rate"] * 100, w_stats["crit_mult"]]
		weapon_bonus_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	if armor_hp_label:
		armor_hp_label.text = "HP: %d" % a_stats["hp"]
		armor_hp_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	if armor_shield_label:
		var shield_str = "护盾: %.0f  护盾回充: %.1f/s" % [a_stats["shield_total"], a_stats["regen_total"]]
		if a_stats["shield_bonus"] != 0.0 or a_stats["regen_bonus"] != 0.0:
			shield_str += "  (+%.0f/+%.1f)" % [a_stats["shield_bonus"], a_stats["regen_bonus"]]
		armor_shield_label.text = shield_str
		armor_shield_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	if ship_hp_label:
		ship_hp_label.text = "HP: %d  基础护盾: %.0f" % [a_stats["hp"], a_stats["shield_base"]]
		ship_hp_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	if ship_slots_label:
		ship_slots_label.text = "武:%d/%d | 防:%d/%d" % [
			_get_equipped_weapon_count(), _get_weapon_slot_counts(),
			_get_equipped_armor_count(), _get_armor_slot_counts()]
		ship_slots_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))

func _get_equipped_weapon_count() -> int:
	var sid = _get_ship_id()
	var list: Array = GameState.equipped_weapons.get(sid, [])
	if not (list is Array):
		return 0
	return list.size()

func _get_equipped_armor_count() -> int:
	var sid = _get_ship_id()
	var list: Array = GameState.equipped_armor.get(sid, [])
	if not (list is Array):
		return 0
	return list.size()

func _update_side_titles() -> void:
	var w_max = _get_weapon_slot_counts()
	var a_max = _get_armor_slot_counts()
	var w_count = _get_equipped_weapon_count()
	var a_count = _get_equipped_armor_count()

	var inv_items = _get_inventory_items()

	if equipped_weapons_title:
		equipped_weapons_title.text = "武器槽 (%d/%d)" % [w_count, w_max]
	if equipped_armor_title:
		equipped_armor_title.text = "防御槽 (%d/%d)" % [a_count, a_max]
	if inventory_title:
		inventory_title.text = "仓库库存 (%d)" % inv_items.size()

func _get_inventory_items() -> Array:
	var sid = _get_ship_id()
	var equipped_ids: Array = []
	var equipped_weapons: Array = GameState.equipped_weapons.get(sid, [])
	if equipped_weapons is Array:
		for w in equipped_weapons:
			if w is Dictionary:
				equipped_ids.append(w.get("equip_id", ""))
	var equipped_armor_list: Array = GameState.equipped_armor.get(sid, [])
	if not (equipped_armor_list is Array):
		equipped_armor_list = []
	for a in equipped_armor_list:
		if a is Dictionary:
			equipped_ids.append(a.get("equip_id", ""))

	var items: Array = []
	for item in GameState.equipment_inventory:
		if not equipped_ids.has(item.get("equip_id", "")):
			items.append(item)
	return items

func _build_ship_info_bar() -> void:
	if not ship_info_label:
		return
	var ship = _get_ship()
	var ship_name = ship.display_name if ship else "护卫舰"
	ship_info_label.text = "%s | 武器槽: %d | 防御槽: %d" % [
		ship_name, _get_weapon_slot_counts(), _get_armor_slot_counts()]

func _get_ship_tonnage() -> int:
	var ship = _get_ship()
	return ship.tonnage_tier if ship else EquipmentData.TonnageTier.SMALL

func _can_equip(item: Dictionary) -> bool:
	var equip_type_val = item.get("equip_type", "WEAPON")
	if typeof(equip_type_val) == TYPE_STRING and equip_type_val.to_upper() == "ARMOR":
		return true
	var equip_tonnage = item.get("tonnage_tier", EquipmentData.TonnageTier.SMALL)
	var ship_tonnage = _get_ship_tonnage()
	return EquipmentData.can_equip_on_ship(ship_tonnage, equip_tonnage)

func _build_equipped_weapons() -> void:
	if not equipped_weapons_grid:
		return
	for child in equipped_weapons_grid.get_children():
		child.queue_free()

	var w_max = _get_weapon_slot_counts()
	var equipped = GameState.equipped_weapons.get(_get_ship_id(), [])
	if not (equipped is Array):
		equipped = []

	var equipped_count = 0
	for w in equipped:
		if w is Dictionary:
			var btn = _make_item_btn(w, true, false)
			equipped_weapons_grid.add_child(btn)
			_apply_item_btn_styles(btn, w, true)
			equipped_count += 1

	for i in range(equipped_count, w_max):
		equipped_weapons_grid.add_child(_make_empty_slot_btn(false))

func _build_equipped_armor() -> void:
	if not equipped_armor_grid:
		return
	for child in equipped_armor_grid.get_children():
		child.queue_free()

	var a_max = _get_armor_slot_counts()
	var armor_list: Array = GameState.equipped_armor.get(_get_ship_id(), [])
	if not (armor_list is Array):
		armor_list = []

	for armor_item in armor_list:
		var btn = _make_item_btn(armor_item, true, true)
		equipped_armor_grid.add_child(btn)
		_apply_item_btn_styles(btn, armor_item, true)

	for i in range(armor_list.size(), a_max):
		equipped_armor_grid.add_child(_make_empty_slot_btn(true))

func _build_inventory() -> void:
	if not inventory_grid:
		return
	for child in inventory_grid.get_children():
		child.queue_free()

	var items = _get_inventory_items()

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

func _make_item_btn(item: Dictionary, is_equipped: bool, is_armor: bool) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 80)
	var quality = item.get("quality", 0)
	var color = EquipmentData.get_quality_color(quality)
	var name_short = item.get("name", "?")
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

	var ship_id = _get_ship_id()
	var equip_id = selected_item.get("equip_id", "")
	var equip_type_val = selected_item.get("equip_type", "")
	var is_armor = false
	if typeof(equip_type_val) == TYPE_STRING:
		is_armor = equip_type_val.to_upper() == "ARMOR"

	var inventory_item: Dictionary = {}
	for item in GameState.equipment_inventory:
		if item.get("equip_id", "") == equip_id:
			inventory_item = item
			break

	if inventory_item.is_empty():
		return

	if is_armor:
		var slots = _get_armor_slot_counts()
		var armor_list: Array = GameState.equipped_armor.get(ship_id, [])
		if not (armor_list is Array):
			armor_list = []
		if armor_list.size() >= slots:
			_show_armor_slots_full_warning()
			return
		if armor_list.any(func(a): return a is Dictionary and a.get("equip_id", "") == equip_id):
			return
		var armor_copy = inventory_item.duplicate(true)
		if not armor_copy.has("equip_type"):
			armor_copy["equip_type"] = "ARMOR"
		armor_list.append(armor_copy)
		GameState.equipped_armor[ship_id] = armor_list
		GameState.equipment_inventory.erase(inventory_item)
	else:
		var slots = _get_weapon_slot_counts()
		var equipped_list: Array = GameState.equipped_weapons.get(ship_id, [])
		if not (equipped_list is Array):
			equipped_list = []
		if equipped_list.size() >= slots:
			return
		if equipped_list.any(func(w): return w is Dictionary and w.get("equip_id", "") == equip_id):
			return
		equipped_list.append(inventory_item.duplicate(true))
		GameState.equipped_weapons[ship_id] = equipped_list

	GameState.equipment_inventory.erase(inventory_item)
	selected_item = {}
	_selected_equip_id = ""
	_build_all()
	GameState.save_game()

func _show_armor_slots_full_warning() -> void:
	print("[WarehouseUI] 防具槽位已满，无法装备更多防具")
	var msg = "防具槽位已满"
	if has_node("ArmorSlotsFullWarning"):
		var w = find_child("ArmorSlotsFullWarning", true, false)
		if w:
			w.text = msg
			w.visible = true
			return

func _show_tonnage_warning() -> void:
	var tonnage = _get_ship_tonnage()
	var t_name = EquipmentData.get_tonnage_name(tonnage)
	var msg = "当前舰船无法装备此吨位装备\n只能装备 %s 及以下吨位" % t_name
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
	var ship_id = _get_ship_id()
	var equip_id = _selected_equip_id
	var equip_type_val = selected_item.get("equip_type", "")
	var is_armor = false
	if typeof(equip_type_val) == TYPE_STRING:
		is_armor = equip_type_val.to_upper() == "ARMOR"

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
		GameState.equipment_inventory.erase(selected_item)
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
	GameState.save_game()

func _update_detail_panel() -> void:
	if selected_item.is_empty():
		if detail_name:
			detail_name.text = "选择一件装备查看详情"
			detail_name.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		if detail_stats:
			detail_stats.text = ""
		if detail_compare:
			detail_compare.text = ""
		if detail_desc:
			detail_desc.text = ""
		if detail_icon:
			detail_icon.text = "[?]"
		if sell_price_label:
			sell_price_label.text = "出售: --"
		return

	var q = selected_item.get("quality", 0)
	var color = EquipmentData.get_quality_color(q)
	var name = selected_item.get("name", "未知装备")
	var equip_type_val = selected_item.get("equip_type", "")
	var is_armor = false
	if typeof(equip_type_val) == TYPE_STRING:
		is_armor = equip_type_val.to_upper() == "ARMOR"

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
	var compare_text = ""
	if is_armor:
		var shield = selected_item.get("shield_bonus", 0.0)
		var regen = selected_item.get("shield_regen_bonus", 0.0)
		var lines: Array = []
		lines.append("护盾上限 +%.0f" % shield)
		lines.append("护盾回充 +%.1f/s" % regen)
		stats_text = "  |  ".join(lines)

		if not _selected_equipped:
			var a_stats = _get_total_armor_stats()
			var diff_shield = shield
			var diff_regen = regen
			var parts: Array = []
			if diff_shield != 0.0:
				var sign = "+" if diff_shield > 0 else ""
				parts.append("护盾上限 %s%.0f" % [sign, diff_shield])
			if diff_regen != 0.0:
				var sign = "+" if diff_regen > 0 else ""
				parts.append("护盾回充 %s%.1f" % [sign, diff_regen])
			if not parts.is_empty():
				compare_text = "[装备后] " + "  ".join(parts)
				detail_compare.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
			else:
				compare_text = ""
		else:
			compare_text = ""
	else:
		var item_stats = _get_weapon_stats_from_dict(selected_item)
		var interval = item_stats["fire_interval"]
		var dps = item_stats["dps"]
		var dmg = item_stats["damage"]
		var rng = item_stats["range"]
		var cr = item_stats["crit_rate"]
		var cm = item_stats["crit_mult"]
		var firerate_str = "%.2f" % (1.0 / interval) if interval > 0 else "0"

		stats_text = "DPS: %.0f  伤害: %.0f  射速: %s/s  射程: %.0f\n暴击率: %.0f%%  暴击倍率: %.1fx" % [
			dps, dmg, firerate_str,
			rng, cr * 100, cm]

		if not _selected_equipped:
			var w_stats = _get_total_weapon_stats()
			var diff_dps = dps - w_stats["dps"]
			var diff_dmg = dmg - w_stats["damage"]
			var diff_range = rng - w_stats["range"]

			var parts: Array = []
			if diff_dps != 0.0:
				var sign = "+" if diff_dps > 0 else ""
				parts.append("DPS %s%.0f" % [sign, diff_dps])
			if diff_dmg != 0.0:
				var sign = "+" if diff_dmg > 0 else ""
				parts.append("伤害 %s%.0f" % [sign, diff_dmg])
			if diff_range != 0.0:
				var sign = "+" if diff_range > 0 else ""
				parts.append("射程 %s%.0f" % [sign, diff_range])
			if not parts.is_empty():
				compare_text = "[装备后] " + "  ".join(parts)
				detail_compare.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
			else:
				compare_text = ""
		else:
			compare_text = ""

	if detail_stats:
		detail_stats.text = stats_text
		detail_stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	if detail_compare:
		detail_compare.text = compare_text

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
	GameState.save_game()

func _on_back() -> void:
	get_parent().close_all_panels()
