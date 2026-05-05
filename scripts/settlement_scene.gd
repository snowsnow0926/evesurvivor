extends Control

const EquipmentData = preload("res://resources/equipment_data.gd")
const WeaponData = preload("res://resources/weapon_data.gd")

var settlement_reason: String = ""
var session_kills: int = 0
var session_level: int = 1
var earned_coin: int = 0
var earned_minerals_low: int = 0
var earned_minerals_mid: int = 0
var earned_minerals_high: int = 0
var pre_loot_coin: int = 0
var pre_loot_minerals_low: int = 0
var pre_loot_minerals_mid: int = 0
var pre_loot_minerals_high: int = 0
var session_loot: Array = []
var elapsed_time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _format_number(n: int) -> String:
	if n >= 1_000_000:
		var mil := n / 1_000_000
		var rem := n % 1_000_000
		if rem == 0:
			return "%dM" % mil
		return "%d,%03d,%03d" % [mil, rem / 1000, rem % 1000]
	elif n >= 1000:
		var k := n / 1000
		var rem := n % 1000
		if rem == 0:
			return "%dk" % k
		return "%d,%03d" % [k, rem]
	return "%d" % n

func set_settlement_data(reason: String, kills: int, level: int,
		p_earned_coin: int, p_earned_low: int, p_earned_mid: int, p_earned_high: int,
		p_pre_coin: int, p_pre_min_low: int, p_pre_min_mid: int, p_pre_min_high: int,
		loot: Array = [], p_elapsed: float = 0.0) -> void:
	settlement_reason = reason
	GameState.last_run_reason = reason

	session_kills = kills
	session_level = level
	earned_coin = p_earned_coin
	earned_minerals_low = p_earned_low
	earned_minerals_mid = p_earned_mid
	earned_minerals_high = p_earned_high
	pre_loot_coin = p_pre_coin
	pre_loot_minerals_low = p_pre_min_low
	pre_loot_minerals_mid = p_pre_min_mid
	pre_loot_minerals_high = p_pre_min_high
	elapsed_time = p_elapsed

	if loot is Array:
		session_loot = loot.duplicate(true)
	else:
		session_loot = []

	_update_display()
	_build_loot_list()

func _update_display() -> void:
	var title_label = get_node_or_null("Panel/VBox/TitleLabel")
	if title_label:
		match settlement_reason:
			"dead":
				title_label.text = "任务失败"
			"timeout":
				title_label.text = "时间到！"
			"retreat":
				title_label.text = "撤退结算"
			"self_destruct":
				title_label.text = "任务中止"
			_:
				title_label.text = "撤退结算"

	# ----- 星币 -----
	var coin_pre = get_node_or_null("Panel/VBox/IncomeVBox/CoinRow/CoinPreValue")
	if coin_pre:
		coin_pre.text = _format_number(pre_loot_coin)
	var coin_earned = get_node_or_null("Panel/VBox/IncomeVBox/CoinRow/CoinEarnedValue")
	if coin_earned:
		coin_earned.text = _format_number(earned_coin)
	var coin_total = get_node_or_null("Panel/VBox/IncomeVBox/CoinRow/CoinTotalValue")
	if coin_total:
		coin_total.text = _format_number(pre_loot_coin + earned_coin)

	# ----- 矿物：低 -----
	var min_low_pre = get_node_or_null("Panel/VBox/IncomeVBox/MinLowRow/MinLowPreValue")
	if min_low_pre:
		min_low_pre.text = _format_number(pre_loot_minerals_low)
	var min_low_earned = get_node_or_null("Panel/VBox/IncomeVBox/MinLowRow/MinLowEarnedValue")
	if min_low_earned:
		min_low_earned.text = _format_number(earned_minerals_low)
	var min_low_total = get_node_or_null("Panel/VBox/IncomeVBox/MinLowRow/MinLowTotalValue")
	if min_low_total:
		min_low_total.text = _format_number(pre_loot_minerals_low + earned_minerals_low)

	# ----- 矿物：中 -----
	var min_mid_pre = get_node_or_null("Panel/VBox/IncomeVBox/MinMidRow/MinMidPreValue")
	if min_mid_pre:
		min_mid_pre.text = _format_number(pre_loot_minerals_mid)
	var min_mid_earned = get_node_or_null("Panel/VBox/IncomeVBox/MinMidRow/MinMidEarnedValue")
	if min_mid_earned:
		min_mid_earned.text = _format_number(earned_minerals_mid)
	var min_mid_total = get_node_or_null("Panel/VBox/IncomeVBox/MinMidRow/MinMidTotalValue")
	if min_mid_total:
		min_mid_total.text = _format_number(pre_loot_minerals_mid + earned_minerals_mid)

	# ----- 矿物：高 -----
	var min_high_pre = get_node_or_null("Panel/VBox/IncomeVBox/MinHighRow/MinHighPreValue")
	if min_high_pre:
		min_high_pre.text = _format_number(pre_loot_minerals_high)
	var min_high_earned = get_node_or_null("Panel/VBox/IncomeVBox/MinHighRow/MinHighEarnedValue")
	if min_high_earned:
		min_high_earned.text = _format_number(earned_minerals_high)
	var min_high_total = get_node_or_null("Panel/VBox/IncomeVBox/MinHighRow/MinHighTotalValue")
	if min_high_total:
		min_high_total.text = _format_number(pre_loot_minerals_high + earned_minerals_high)

func _shop_item_id_to_weapon_id(sid: int) -> int:
	match sid:
		0: return 4
		1: return 8
		2: return 12
		3: return 16
		4: return 5
		5: return 9
		6: return 13
		7: return 17
		8: return 6
		9: return 10
		10: return 14
		11: return 18
		12: return 7
		13: return 11
		14: return 15
		15: return 19
	return 0

func _build_loot_list() -> void:
	var loot_scroll = get_node_or_null("Panel/VBox/LootScroll")
	var loot_container = get_node_or_null("Panel/VBox/LootScroll/LootContainer")
	var empty_label = get_node_or_null("Panel/VBox/LootScroll/LootContainer/EmptyLootLabel")
	var section_label = get_node_or_null("Panel/VBox/SectionLoot")
	var separator2 = get_node_or_null("Panel/VBox/Separator2")

	var has_loot := session_loot.size() > 0

	if section_label:
		section_label.visible = true
	if separator2:
		separator2.visible = true
	if loot_scroll:
		loot_scroll.visible = true
	if empty_label:
		empty_label.visible = not has_loot

	if not loot_container:
		return
	for child in loot_container.get_children():
		child.queue_free()

	if not has_loot:
		return

	for loot: Dictionary in session_loot:
		var row := HBoxContainer.new()
		var type_str := "武器" if loot.get("type") == "weapon" else "防具"
		var name_str := ""
		var quality_color := Color.WHITE
		if loot.get("type") == "weapon":
			var wid: int = loot.get("weapon_id", 0)
			if wid == 0:
				var sid: int = loot.get("shop_item_id", 0)
				wid = _shop_item_id_to_weapon_id(sid)
			var wd := WeaponData.get_weapon(wid)
			name_str = wd.display_name if wd else loot.get("name", "?")
			quality_color = EquipmentData.get_quality_color(loot.get("quality", 0))
		else:
			var aid: int = loot.get("armor_id", 0)
			name_str = EquipmentData.get_armor_name(aid) if aid >= 0 else loot.get("name", "?")
			quality_color = EquipmentData.get_quality_color(loot.get("quality", 0))
		var name_label := Label.new()
		name_label.text = "- %s [%s]" % [type_str, name_str]
		name_label.add_theme_color_override("font_color", quality_color)
		row.add_child(name_label)
		loot_container.add_child(row)
