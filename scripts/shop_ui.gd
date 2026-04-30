extends Control

const ShopItemData = preload("res://resources/shop_data.gd")
const EquipmentData = preload("res://resources/equipment_data.gd")
const ShipData = preload("res://resources/ship_data.gd")

var weapon_list_vbox: VBoxContainer
var detail_title: Label
var detail_desc: Label
var detail_stats: Label
var detail_cost: Label
var buy_btn: Button
var sell_btn: Button
var coin_label: Label
var minerals_label: Label
var back_btn: Button
var tab_weapons_btn: Button
var tab_armor_btn: Button
var list_label: Label

var selected_shop_item: ShopItemData = null
var selected_inventory_item: Dictionary = {}
var _current_tab: String = "weapon"
var _initialized: bool = false

func _ready() -> void:
	visible = false
	call_deferred("_deferred_init")

func _deferred_init() -> void:
	weapon_list_vbox = find_child("VBox", true, false)
	var weapon_list_scroll = find_child("WeaponList", true, false)
	if weapon_list_scroll and weapon_list_scroll is ScrollContainer:
		weapon_list_vbox = weapon_list_scroll.find_child("VBox", true, false)

	detail_title = find_child("DetailTitle", true, false)
	detail_desc = find_child("DetailDesc", true, false)
	detail_stats = find_child("DetailStats", true, false)
	detail_cost = find_child("DetailCost", true, false)
	buy_btn = find_child("BuyBtn", true, false)
	sell_btn = find_child("SellBtn", true, false)
	coin_label = find_child("CoinLabel", true, false)
	minerals_label = find_child("MineralsLabel", true, false)
	back_btn = find_child("BackBtn", true, false)
	tab_weapons_btn = find_child("TabWeapons", true, false)
	tab_armor_btn = find_child("TabArmor", true, false)
	list_label = find_child("WeaponListLabel", true, false)

	if back_btn:
		back_btn.pressed.connect(_on_back)
	if buy_btn:
		buy_btn.pressed.connect(_on_buy)
	if sell_btn:
		sell_btn.pressed.connect(_on_sell)
	if tab_weapons_btn:
		tab_weapons_btn.pressed.connect(_on_tab_weapons)
	if tab_armor_btn:
		tab_armor_btn.pressed.connect(_on_tab_armor)

	_build_weapon_list()
	_update_currency_display()
	_initialized = true

func _process(delta: float) -> void:
	if _initialized:
		_update_currency_display()

func _build_weapon_list() -> void:
	if not weapon_list_vbox:
		return
	for child in weapon_list_vbox.get_children():
		child.queue_free()

	var all_items = ShopItemData.get_all_shop_items()
	var filtered: Array[ShopItemData] = []
	for item in all_items:
		if _current_tab == "weapon" and item.equip_type == ShopItemData.EquipType.WEAPON:
			filtered.append(item)
		elif _current_tab == "armor" and item.equip_type == ShopItemData.EquipType.ARMOR:
			filtered.append(item)

	for item in filtered:
		var btn = Button.new()
		btn.text = "%s  |  %d 星币" % [
			item.display_name,
			item.star_coin_price,
		]
		btn.custom_minimum_size = Vector2(0, 48)
		btn.pressed.connect(_on_shop_item_selected.bind(item))
		weapon_list_vbox.add_child(btn)

	if list_label:
		if _current_tab == "weapon":
			list_label.text = "装备列表"
		else:
			list_label.text = "防御列表"

	selected_shop_item = null
	selected_inventory_item = {}
	_update_detail_panel()

func _on_tab_weapons() -> void:
	_current_tab = "weapon"
	if tab_weapons_btn:
		tab_weapons_btn.set_pressed_no_signal(true)
	if tab_armor_btn:
		tab_armor_btn.set_pressed_no_signal(false)
	_build_weapon_list()

func _on_tab_armor() -> void:
	_current_tab = "armor"
	if tab_weapons_btn:
		tab_weapons_btn.set_pressed_no_signal(false)
	if tab_armor_btn:
		tab_armor_btn.set_pressed_no_signal(true)
	_build_weapon_list()

func _on_shop_item_selected(item: ShopItemData) -> void:
	selected_shop_item = item
	selected_inventory_item = {}
	_update_detail_panel()

func _update_detail_panel() -> void:
	if not _initialized:
		return
	if selected_shop_item != null:
		if detail_title:
			detail_title.text = selected_shop_item.display_name
		if detail_desc:
			detail_desc.text = selected_shop_item.description
		if detail_stats:
			if selected_shop_item.equip_type == ShopItemData.EquipType.WEAPON:
				detail_stats.text = "伤害: %.0f  |  射速: %.2f/s  |  射程: %.0f\n暴击率: %.0f%%  |  暴击倍率: %.1fx" % [
					selected_shop_item.base_damage,
					1.0 / selected_shop_item.fire_interval,
					selected_shop_item.range,
					selected_shop_item.crit_rate * 100,
					selected_shop_item.crit_mult
				]
			else:
				var lines: Array = []
				if selected_shop_item.shield_bonus > 0:
					lines.append("护盾上限 +%.0f" % selected_shop_item.shield_bonus)
				if selected_shop_item.shield_regen_bonus > 0:
					lines.append("护盾回充 +%.0f/s" % selected_shop_item.shield_regen_bonus)
				detail_stats.text = "\n".join(lines)
		if detail_cost:
			detail_cost.text = "价格: %d 星币\n出售价: %d 星币" % [
				selected_shop_item.star_coin_price,
				selected_shop_item.sell_price
			]
		_update_buy_button()
		if buy_btn: buy_btn.visible = true
		if sell_btn: sell_btn.visible = false
	elif not selected_inventory_item.is_empty():
		if detail_title:
			detail_title.text = selected_inventory_item.get("name", "?")
		if detail_desc:
			detail_desc.text = selected_inventory_item.get("description", "")
		var sell_price = int(selected_inventory_item.get("star_coin_price", 0) * 0.4)
		if detail_cost:
			detail_cost.text = "出售价: %d 星币" % sell_price
		if buy_btn: buy_btn.visible = false
		if sell_btn: sell_btn.visible = true
	else:
		if detail_title: detail_title.text = "选择装备查看详情"
		if detail_desc: detail_desc.text = ""
		if detail_stats: detail_stats.text = ""
		if detail_cost: detail_cost.text = ""
		if buy_btn: buy_btn.visible = false
		if sell_btn: sell_btn.visible = false

func _update_buy_button() -> void:
	if not buy_btn:
		return
	if selected_shop_item == null:
		buy_btn.disabled = true
		return
	buy_btn.disabled = not _can_afford_shop_item(selected_shop_item)

func _can_afford_shop_item(item: ShopItemData) -> bool:
	return GameState.star_coin >= item.star_coin_price

func _on_buy() -> void:
	if selected_shop_item == null or not _can_afford_shop_item(selected_shop_item):
		return

	GameState.star_coin -= selected_shop_item.star_coin_price

	var item_dict = selected_shop_item.to_inventory_dict()

	if selected_shop_item.equip_type == ShopItemData.EquipType.ARMOR:
		_buy_armor(item_dict)
	else:
		_buy_weapon(item_dict)

	_update_currency_display()
	_update_buy_button()

func _buy_weapon(item_dict: Dictionary) -> void:
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE

	var ship = ShipData.get_ship(ship_id)
	if not ship:
		GameState.equipment_inventory.append(item_dict)
		return

	GameState.equipment_inventory.append(item_dict)

	var weapon_slot_count = ship.weapon_slot_count
	if GameState.upgraded_ships.get(ship_id, false):
		weapon_slot_count = ship.upgraded_weapon_slots

	if not GameState.equipped_weapons.has(ship_id):
		GameState.equipped_weapons[ship_id] = []

	var equipped_list: Array = GameState.equipped_weapons[ship_id]
	if not (equipped_list is Array):
		equipped_list = []
		GameState.equipped_weapons[ship_id] = equipped_list

	if equipped_list.size() < weapon_slot_count:
		equipped_list.append(item_dict)
		GameState.equipped_weapons[ship_id] = equipped_list
		print("[ShopUI] auto equip weapon to ship ", ship_id, ", equipped count now: ", equipped_list.size())
	else:
		print("[ShopUI] slots full (", weapon_slot_count, "), weapon stays in inventory")

func _buy_armor(item_dict: Dictionary) -> void:
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE

	GameState.selected_ship_id = ship_id

	var ship = ShipData.get_ship(ship_id)
	if not ship:
		GameState.equipment_inventory.append(item_dict)
		return

	var ship_id_key = ship.ship_id
	var armor_slot_count = ship.armor_slot_count
	if GameState.upgraded_ships.get(ship_id_key, false):
		armor_slot_count = ship.upgraded_armor_slots

	var current_armor = GameState.equipped_armor.get(ship_id_key, {})

	if not current_armor.is_empty():
		var old_dict = current_armor.duplicate()
		old_dict["equip_id"] = current_armor.get("equip_id", "") + "_old"
		GameState.equipment_inventory.append(old_dict)

	GameState.equipped_armor[ship_id_key] = item_dict
	GameState.equipment_inventory.append(item_dict)

func _on_sell() -> void:
	if selected_inventory_item.is_empty():
		return
	var sell_price = int(selected_inventory_item.get("star_coin_price", 0) * 0.4)
	if sell_price == 0:
		sell_price = int(selected_inventory_item.get("base_damage", 10) * 5)
	GameState.star_coin += sell_price
	GameState.equipment_inventory.erase(selected_inventory_item)
	selected_inventory_item = {}
	_update_detail_panel()
	_update_currency_display()

func _update_currency_display() -> void:
	if coin_label:
		coin_label.text = "星币: %d" % GameState.star_coin
	if minerals_label:
		minerals_label.text = "矿物: %d低 / %d中 / %d高" % [
			GameState.minerals_low, GameState.minerals_mid, GameState.minerals_high]

func _on_back() -> void:
	get_parent().close_all_panels()
