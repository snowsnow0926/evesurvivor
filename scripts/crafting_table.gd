extends Control

const EquipmentData = preload("res://resources/equipment_data.gd")
const ShipData = preload("res://resources/ship_data.gd")

@onready var inventory_grid: GridContainer = $Panel/VBox/InventoryGrid
@onready var crafting_slots: HBoxContainer = $Panel/VBox/CraftingSlots
@onready var result_preview: Label = $Panel/VBox/ResultPreview
@onready var craft_btn: Button = $Panel/VBox/CraftBtn
@onready var quick_craft_btn: Button = $Panel/VBox/QuickCraftBtn
@onready var back_btn: Button = $Panel/VBox/BackBtn

var selected_items: Array = [null, null]

const CRAFTING_COSTS: Dictionary = {
	EquipmentData.Quality.COMMON: 200,
	EquipmentData.Quality.UNCOMMON: 500,
	EquipmentData.Quality.RARE: 1500,
	EquipmentData.Quality.LEGENDARY: 5000,
	EquipmentData.Quality.EPIC: 20000,
}

func _ready() -> void:
	if craft_btn:
		craft_btn.pressed.connect(_on_craft_pressed)
	if quick_craft_btn:
		quick_craft_btn.pressed.connect(_on_quick_craft_pressed)
	if back_btn:
		back_btn.pressed.connect(_on_back)
	_build_inventory()

func _build_inventory() -> void:
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
	var equipped_armor: Array = GameState.equipped_armor.get(ship_id, [])
	if not (equipped_armor is Array):
		equipped_armor = []
	for armor_item in equipped_armor:
		if armor_item is Dictionary:
			equipped_ids.append(armor_item.get("equip_id", ""))

	for item in GameState.equipment_inventory:
		var equip_id = item.get("equip_id", "")
		if equipped_ids.has(equip_id):
			continue
		var btn = _make_item_button(item)
		inventory_grid.add_child(btn)

func _make_item_button(item: Dictionary) -> Button:
	var btn = Button.new()
	btn.text = item.get("name", "?")
	var q = item.get("quality", 0)
	btn.add_theme_color_override("font_color", EquipmentData.get_quality_color(q))
	btn.custom_minimum_size = Vector2(80, 80)
	btn.pressed.connect(_on_item_selected.bind(item))
	return btn

func _on_item_selected(item: Dictionary) -> void:
	for i in range(2):
		if selected_items[i] != null and selected_items[i].get("equip_id") == item.get("equip_id"):
			selected_items[i] = null
			_update_crafting_slots()
			return
	for i in range(2):
		if selected_items[i] == null:
			selected_items[i] = item
			_update_crafting_slots()
			return
	_update_preview()

func _update_crafting_slots() -> void:
	for i in range(2):
		var slot = crafting_slots.get_child(i)
		if selected_items[i]:
			slot.get_node("Label").text = selected_items[i].get("name", "?")
		else:
			slot.get_node("Label").text = "[空]"
	_update_preview()

func _get_base_name(item: Dictionary) -> String:
	var raw_name = item.get("name", "")
	for qq in range(EquipmentData.Quality.MYTHIC, -1, -1):
		var prefix = EquipmentData.get_quality_name(qq)
		if raw_name.begins_with(prefix + " "):
			return raw_name.substr(prefix.length() + 1)
	return raw_name

func _can_craft_pair(item_a: Dictionary, item_b: Dictionary) -> bool:
	if item_a.get("quality") != item_b.get("quality"):
		return false
	return _get_base_name(item_a) == _get_base_name(item_b)

func _update_preview() -> void:
	if selected_items[0] == null or selected_items[1] == null:
		result_preview.text = "放入2件同名同品质装备进行合成"
		if craft_btn:
			craft_btn.disabled = true
		return

	if not _can_craft_pair(selected_items[0], selected_items[1]):
		result_preview.text = "需同名同品质才能合成！"
		if craft_btn:
			craft_btn.disabled = true
		return

	var q = selected_items[0].get("quality")
	var next_q = q + 1
	if next_q > EquipmentData.Quality.MYTHIC:
		result_preview.text = "已是最高品质！"
		if craft_btn:
			craft_btn.disabled = true
		return

	var cost = CRAFTING_COSTS.get(q, 0)
	result_preview.text = "合成 %s\n消耗 %d 星币\n当前 %d 星币" % [
		EquipmentData.get_quality_name(next_q), cost, GameState.star_coin]
	if craft_btn:
		craft_btn.disabled = GameState.star_coin < cost

func _on_craft_pressed() -> void:
	if selected_items[0] == null or selected_items[1] == null:
		return
	if not _can_craft_pair(selected_items[0], selected_items[1]):
		return

	var q = selected_items[0].get("quality")
	var next_q = q + 1
	var cost = CRAFTING_COSTS.get(q, 0)

	if GameState.star_coin < cost:
		return

	GameState.star_coin -= cost
	GameState.equipment_inventory.erase(selected_items[0])
	GameState.equipment_inventory.erase(selected_items[1])

	var equip_type_val = selected_items[0].get("equip_type", "")
	var is_weapon = true
	if typeof(equip_type_val) == TYPE_STRING:
		is_weapon = equip_type_val.to_upper() != "ARMOR"

	# Strip all quality prefixes from base_name to avoid stacking
	var raw_name = _get_base_name(selected_items[0])

	var quality_prefix = EquipmentData.get_quality_name(next_q)
	var mult = EquipmentData.get_quality_mult(next_q)

	var new_item = {
		"equip_id": str(randi()),
		"equip_type": selected_items[0].get("equip_type", "WEAPON"),
		"quality": next_q,
		"name": quality_prefix + " " + raw_name,
		"description": selected_items[0].get("description", ""),
		"scene_path": selected_items[0].get("scene_path", ""),
		"tonnage_tier": selected_items[0].get("tonnage_tier", 0),
		"star_coin_price": int(selected_items[0].get("star_coin_price", 0) * mult),
	}

	if is_weapon:
		var base_damage = selected_items[0].get("base_damage", 0.0)
		new_item["base_damage"] = base_damage * mult
		new_item["fire_interval"] = selected_items[0].get("fire_interval", 1.0)
		new_item["range"] = selected_items[0].get("range", 0.0)
		new_item["crit_rate"] = selected_items[0].get("crit_rate", 0.0)
		new_item["crit_mult"] = selected_items[0].get("crit_mult", 1.5)
	else:
		new_item["shield_bonus"] = selected_items[0].get("shield_bonus", 0.0) * mult
		new_item["shield_regen_bonus"] = selected_items[0].get("shield_regen_bonus", 0.0) * mult

	GameState.equipment_inventory.append(new_item)

	selected_items = [null, null]
	GameState.save_game()
	_build_inventory()
	_update_crafting_slots()

func _on_back() -> void:
	get_parent().close_all_panels()

func _on_quick_craft_pressed() -> void:
	var quality_order = [
		EquipmentData.Quality.COMMON,
		EquipmentData.Quality.UNCOMMON,
		EquipmentData.Quality.RARE,
		EquipmentData.Quality.LEGENDARY,
		EquipmentData.Quality.EPIC,
	]
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE

	var equipped_ids: Array = []
	var equipped_weapons = GameState.equipped_weapons.get(ship_id, [])
	if equipped_weapons is Array:
		for w in equipped_weapons:
			if w is Dictionary:
				equipped_ids.append(w.get("equip_id", ""))
	var equipped_armor: Array = GameState.equipped_armor.get(ship_id, [])
	if not (equipped_armor is Array):
		equipped_armor = []
	for armor_item in equipped_armor:
		if armor_item is Dictionary:
			equipped_ids.append(armor_item.get("equip_id", ""))

	var craft_count = 0
	for q in quality_order:
		if q >= EquipmentData.Quality.MYTHIC:
			continue
		var cost = CRAFTING_COSTS.get(q, 0)
		if GameState.star_coin < cost:
			continue

		var by_name: Dictionary = {}
		for item in GameState.equipment_inventory:
			if equipped_ids.has(item.get("equip_id", "")):
				continue
			if item.get("quality", 0) != q:
				continue
			var base_name = _get_base_name(item)
			var key = item.get("equip_type", "WEAPON") + "|" + base_name
			if not by_name.has(key):
				by_name[key] = []
			by_name[key].append(item)

		for key in by_name:
			var group: Array = by_name[key]
			while group.size() >= 2:
				var cost_now = CRAFTING_COSTS.get(q, 0)
				if GameState.star_coin < cost_now:
					break
				var item_a = group[group.size() - 1]
				var item_b = group[group.size() - 2]

				GameState.star_coin -= cost_now
				GameState.equipment_inventory.erase(item_a)
				GameState.equipment_inventory.erase(item_b)

				var is_weapon = true
				var equip_type_val = item_a.get("equip_type", "")
				if typeof(equip_type_val) == TYPE_STRING:
					is_weapon = equip_type_val.to_upper() != "ARMOR"

				var raw_name = _get_base_name(item_a)
				var next_q = q + 1
				var mult = EquipmentData.get_quality_mult(next_q)
				var new_item = {
					"equip_id": str(randi()),
					"equip_type": item_a.get("equip_type", "WEAPON"),
					"quality": next_q,
					"name": EquipmentData.get_quality_name(next_q) + " " + raw_name,
					"description": item_a.get("description", ""),
					"scene_path": item_a.get("scene_path", ""),
					"tonnage_tier": item_a.get("tonnage_tier", 0),
					"star_coin_price": int(item_a.get("star_coin_price", 0) * mult),
				}
				if is_weapon:
					new_item["base_damage"] = item_a.get("base_damage", 0.0) * mult
					new_item["fire_interval"] = item_a.get("fire_interval", 1.0)
					new_item["range"] = item_a.get("range", 0.0)
					new_item["crit_rate"] = item_a.get("crit_rate", 0.0)
					new_item["crit_mult"] = item_a.get("crit_mult", 1.5)
				else:
					new_item["shield_bonus"] = item_a.get("shield_bonus", 0.0) * mult
					new_item["shield_regen_bonus"] = item_a.get("shield_regen_bonus", 0.0) * mult

				GameState.equipment_inventory.append(new_item)
				group.resize(group.size() - 2)
				craft_count += 1

	if craft_count > 0:
		result_preview.text = "一键合成完成！共合成 %d 件" % craft_count
		GameState.save_game()
		_build_inventory()
	else:
		result_preview.text = "无可用配对或星币不足"
	_update_crafting_slots()
