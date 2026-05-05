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
var tonnage_filter_btns: Array[Button] = []

var selected_shop_item: ShopItemData = null
var selected_inventory_item: Dictionary = {}
var _current_tab: String = "weapon"
var _current_tonnage: int = -1
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

	var filter_all = find_child("FilterAll", true, false)
	var filter_small = find_child("FilterSmall", true, false)
	var filter_medium = find_child("FilterMedium", true, false)
	var filter_large = find_child("FilterLarge", true, false)
	var filter_flagship = find_child("FilterFlag", true, false)
	if filter_all:
		tonnage_filter_btns.append(filter_all)
	if filter_small:
		tonnage_filter_btns.append(filter_small)
	if filter_medium:
		tonnage_filter_btns.append(filter_medium)
	if filter_large:
		tonnage_filter_btns.append(filter_large)
	if filter_flagship:
		tonnage_filter_btns.append(filter_flagship)
	for i in range(tonnage_filter_btns.size()):
		var btn = tonnage_filter_btns[i]
		if btn:
			btn.pressed.connect(_on_tonnage_filter.bind(i - 1))

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

func _on_tonnage_filter(filter_idx: int) -> void:
	_current_tonnage = filter_idx
	for i in range(tonnage_filter_btns.size()):
		var btn = tonnage_filter_btns[i]
		if btn:
			btn.set_pressed_no_signal(i - 1 == filter_idx)
	_build_weapon_list()

func _get_ship_tonnage() -> int:
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE
	var ship = ShipData.get_ship(ship_id)
	return ship.tonnage_tier if ship else EquipmentData.TonnageTier.SMALL

func _build_weapon_list() -> void:
	if not weapon_list_vbox:
		return
	for child in weapon_list_vbox.get_children():
		child.queue_free()

	var all_items: Array[ShopItemData] = ShopItemData.get_all_shop_items()
	var filtered: Array[ShopItemData] = []
	for item in all_items:
		if not (item is ShopItemData):
			continue
		if _current_tab == "weapon" and item.equip_type == ShopItemData.EquipType.WEAPON:
			filtered.append(item)
		elif _current_tab == "armor" and item.equip_type == ShopItemData.EquipType.ARMOR:
			filtered.append(item)

	var ship_tonnage = _get_ship_tonnage()

	for item in filtered:
		if _current_tonnage >= 0:
			if item.tonnage_tier != _current_tonnage:
				continue

		var btn = Button.new()
		var t_name = EquipmentData.get_tonnage_name(item.tonnage_tier)
		btn.text = "%s %s  |  %d 星币" % [
			t_name,
			item.display_name,
			item.star_coin_price,
		]
		btn.custom_minimum_size = Vector2(0, 48)
		btn.pressed.connect(_on_shop_item_selected.bind(item))
		btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		weapon_list_vbox.add_child(btn)

	if list_label:
		var tab_name = "装备列表" if _current_tab == "weapon" else "防御列表"
		var filter_name = "全部" if _current_tonnage < 0 else EquipmentData.get_tonnage_name(_current_tonnage)
		list_label.text = "%s (%s)" % [tab_name, filter_name]

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
		var ship_tonnage = _get_ship_tonnage()
		var can_equip = EquipmentData.can_equip_on_ship(ship_tonnage, selected_shop_item.tonnage_tier)
		var t_name = EquipmentData.get_tonnage_name(selected_shop_item.tonnage_tier)

		if detail_title:
			detail_title.text = "[%s] %s" % [t_name, selected_shop_item.display_name]
			detail_title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		if detail_desc:
			detail_desc.text = selected_shop_item.description
		if detail_stats:
			if selected_shop_item.equip_type == ShopItemData.EquipType.WEAPON:
				detail_stats.text = "伤害: %.0f  |  射速: %.2f/s  |  射程: %.0f\n暴击率: %.0f%%  |  暴击倍率: %.1fx\n吨位: %s" % [
					selected_shop_item.base_damage,
					1.0 / selected_shop_item.fire_interval,
					selected_shop_item.range,
					selected_shop_item.crit_rate * 100,
					selected_shop_item.crit_mult,
					t_name
				]
			else:
				var lines: Array = []
				if selected_shop_item.shield_bonus > 0:
					lines.append("护盾上限 +%.0f" % selected_shop_item.shield_bonus)
				if selected_shop_item.shield_regen_bonus > 0:
					lines.append("护盾回充 +%.0f/s" % selected_shop_item.shield_regen_bonus)
				lines.append("吨位: %s" % t_name)
				detail_stats.text = "\n".join(lines)
		if detail_cost:
			detail_cost.text = "价格: %d 星币\n出售价: %d 星币" % [
				selected_shop_item.star_coin_price,
				selected_shop_item.sell_price
			]
			if not can_equip:
				detail_cost.text += "\n[当前舰船无法装备此吨位]"
				detail_cost.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			else:
				detail_cost.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		_update_buy_button()
		if buy_btn: buy_btn.visible = true
		if sell_btn: sell_btn.visible = false
	elif not selected_inventory_item.is_empty():
		var q = selected_inventory_item.get("quality", 0)
		if detail_title:
			detail_title.text = selected_inventory_item.get("name", "?")
			detail_title.add_theme_color_override("font_color", EquipmentData.get_quality_color(q))
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
		if detail_cost:
			detail_cost.text = ""
			detail_cost.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		if buy_btn: buy_btn.visible = false
		if sell_btn: sell_btn.visible = false

func _update_buy_button() -> void:
	if not buy_btn:
		return
	if selected_shop_item == null:
		buy_btn.disabled = true
		return
	var can_equip = EquipmentData.can_equip_on_ship(_get_ship_tonnage(), selected_shop_item.tonnage_tier)
	buy_btn.disabled = not _can_afford_shop_item(selected_shop_item) or not can_equip
	if buy_btn.disabled and can_equip and not _can_afford_shop_item(selected_shop_item):
		buy_btn.text = "星币不足"
	elif not can_equip:
		buy_btn.text = "舰船吨位不足"
	else:
		buy_btn.text = "购买"

func _can_afford_shop_item(item: ShopItemData) -> bool:
	return GameState.star_coin >= item.star_coin_price

func _on_buy() -> void:
	if selected_shop_item == null or not _can_afford_shop_item(selected_shop_item):
		return
	var ship_tonnage = _get_ship_tonnage()
	if not EquipmentData.can_equip_on_ship(ship_tonnage, selected_shop_item.tonnage_tier):
		return

	GameState.star_coin -= selected_shop_item.star_coin_price
	GameState.save_game()

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
		GameState.equipment_inventory.erase(item_dict)

func _buy_armor(item_dict: Dictionary) -> void:
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE

	var ship = ShipData.get_ship(ship_id)
	if not ship:
		GameState.equipment_inventory.append(item_dict)
		return

	var armor_slot_count = ship.armor_slot_count
	if GameState.upgraded_ships.get(ship_id, false):
		armor_slot_count = ship.upgraded_armor_slots

	if not GameState.equipped_armor.has(ship_id):
		GameState.equipped_armor[ship_id] = []

	var armor_list: Array = GameState.equipped_armor.get(ship_id, [])
	if not (armor_list is Array):
		armor_list = []
		GameState.equipped_armor[ship_id] = armor_list

	if armor_list.size() < armor_slot_count:
		armor_list.append(item_dict)
		GameState.equipped_armor[ship_id] = armor_list
		GameState.equipment_inventory.erase(item_dict)
	else:
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
