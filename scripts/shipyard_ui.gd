extends Control

var ship_list_vbox: VBoxContainer
var preview_title: Label
var ship_name_lbl: Label
var current_slots_lbl: Label
var upgraded_slots_lbl: Label
var cost_info_lbl: Label
var upgrade_btn: Button
var coin_label: Label
var minerals_label: Label
var back_btn: Button

var selected_ship: ShipData = null
var _initialized: bool = false

func _ready() -> void:
	visible = false
	call_deferred("_deferred_init")

func _deferred_init() -> void:
	var ship_list_scroll = find_child("ShipList", true, false)
	if ship_list_scroll and ship_list_scroll is ScrollContainer:
		ship_list_vbox = ship_list_scroll.find_child("VBox", true, false)
	else:
		ship_list_vbox = find_child("VBox", true, false)

	preview_title = find_child("PreviewTitle", true, false)
	ship_name_lbl = find_child("ShipName", true, false)
	current_slots_lbl = find_child("CurrentSlots", true, false)
	upgraded_slots_lbl = find_child("UpgradedSlots", true, false)
	cost_info_lbl = find_child("CostInfo", true, false)
	upgrade_btn = find_child("UpgradeBtn", true, false)
	coin_label = find_child("CoinLabel", true, false)
	minerals_label = find_child("MineralsLabel", true, false)
	back_btn = find_child("BackBtn", true, false)

	if upgrade_btn:
		upgrade_btn.pressed.connect(_on_upgrade)
	if back_btn:
		back_btn.pressed.connect(_on_back)

	_build_ship_list()
	_update_currency_display()
	_initialized = true

func _process(delta: float) -> void:
	if _initialized:
		_update_currency_display()

func _build_ship_list() -> void:
	if not ship_list_vbox:
		return
	for child in ship_list_vbox.get_children():
		child.queue_free()

	var ships = ShipData.get_all_ships()
	for ship in ships:
		var is_unlocked = ship.is_unlocked or GameState.unlocked_ships.has(ship.ship_id)
		if not is_unlocked:
			continue

		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 48)

		var name_lbl = Label.new()
		name_lbl.text = ship.display_name
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var is_upgraded = GameState.upgraded_ships.get(int(ship.ship_id), false)
		var status_lbl = Label.new()
		if is_upgraded:
			status_lbl.text = "[已升级]"
			status_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		else:
			status_lbl.text = "[可升级]"
			status_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		row.add_child(status_lbl)

		var btn = Button.new()
		if is_upgraded:
			btn.text = "查看"
		else:
			btn.text = "升级"
		btn.pressed.connect(_on_ship_row_selected.bind(ship))
		row.add_child(btn)
		ship_list_vbox.add_child(row)

func _on_ship_row_selected(ship: ShipData) -> void:
	selected_ship = ship
	_update_preview_panel()

func _update_preview_panel() -> void:
	if not _initialized:
		return
	if selected_ship == null:
		if preview_title: preview_title.text = "选择舰船查看升级"
		if ship_name_lbl: ship_name_lbl.text = ""
		if current_slots_lbl: current_slots_lbl.text = ""
		if upgraded_slots_lbl: upgraded_slots_lbl.text = ""
		if cost_info_lbl: cost_info_lbl.text = ""
		if upgrade_btn: upgrade_btn.disabled = true
		return

	if preview_title: preview_title.text = ""
	if ship_name_lbl: ship_name_lbl.text = selected_ship.display_name

	var is_upgraded = GameState.upgraded_ships.get(int(selected_ship.ship_id), false)
	if current_slots_lbl:
		current_slots_lbl.text = "当前: 武器x%d 防御x%d" % [selected_ship.weapon_slot_count, selected_ship.armor_slot_count]

	if is_upgraded:
		if current_slots_lbl:
			current_slots_lbl.text = "当前: 武器x%d 防御x%d" % [selected_ship.upgraded_weapon_slots, selected_ship.upgraded_armor_slots]
		if upgraded_slots_lbl: upgraded_slots_lbl.text = "已升级至最大"
		if cost_info_lbl: cost_info_lbl.text = ""
		if upgrade_btn:
			upgrade_btn.disabled = true
			upgrade_btn.text = "已升级"
	else:
		if current_slots_lbl:
			current_slots_lbl.text = "当前: 武器x%d 防御x%d" % [selected_ship.weapon_slot_count, selected_ship.armor_slot_count]
		if upgraded_slots_lbl:
			upgraded_slots_lbl.text = "升级后: 武器x%d 防御x%d" % [selected_ship.upgraded_weapon_slots, selected_ship.upgraded_armor_slots]
		var tier_name = "低级矿物" if selected_ship.upgrade_mineral_tier == 0 else ("中级矿物" if selected_ship.upgrade_mineral_tier == 1 else "高级矿物")
		if cost_info_lbl:
			cost_info_lbl.text = "升级费用:\n%d 星币 + %s x%d\n\n当前余额:\n星币: %d\n%s: %d" % [
				selected_ship.upgrade_star_coin,
				tier_name, selected_ship.upgrade_mineral_count,
				GameState.star_coin,
				tier_name,
				_get_mineral_count(selected_ship.upgrade_mineral_tier)
			]
		if upgrade_btn:
			upgrade_btn.disabled = not _can_afford_upgrade(selected_ship)
			upgrade_btn.text = "升级"

func _can_afford_upgrade(ship: ShipData) -> bool:
	if GameState.star_coin < ship.upgrade_star_coin:
		return false
	var mineral_count = _get_mineral_count(ship.upgrade_mineral_tier)
	return mineral_count >= ship.upgrade_mineral_count

func _get_mineral_count(tier: int) -> int:
	match tier:
		0: return GameState.minerals_low
		1: return GameState.minerals_mid
		2: return GameState.minerals_high
	return 0

func _on_upgrade() -> void:
	if selected_ship == null or not _can_afford_upgrade(selected_ship):
		return

	GameState.star_coin -= selected_ship.upgrade_star_coin
	match selected_ship.upgrade_mineral_tier:
		0: GameState.minerals_low -= selected_ship.upgrade_mineral_count
		1: GameState.minerals_mid -= selected_ship.upgrade_mineral_count
		2: GameState.minerals_high -= selected_ship.upgrade_mineral_count

	GameState.upgraded_ships[int(selected_ship.ship_id)] = true
	_build_ship_list()
	_update_preview_panel()
	_update_currency_display()

func _update_currency_display() -> void:
	if coin_label:
		coin_label.text = "星币: %d" % GameState.star_coin
	if minerals_label:
		minerals_label.text = "矿物: %d低 / %d中 / %d高" % [
			GameState.minerals_low, GameState.minerals_mid, GameState.minerals_high]

func _on_back() -> void:
	get_parent().close_all_panels()
