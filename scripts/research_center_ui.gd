extends Control

const RESEARCH_DATA: Array = [
	{"id": "fire_coverage",    "name": "火力覆盖",    "weapon": "missile",  "max_level": 2,
		"level_costs": [{"coin": 20_000, "mineral": 10_000, "tier": "low"},
		                {"coin": 100_000, "mineral": 50_000, "tier": "mid"}]},
	{"id": "silent_hunter",    "name": "静默猎手",    "weapon": "missile",  "max_level": 2,
		"level_costs": [{"coin": 20_000, "mineral": 10_000, "tier": "low"},
		                {"coin": 100_000, "mineral": 50_000, "tier": "mid"}]},
	{"id": "precision_kill",   "name": "精准猎杀",    "weapon": "missile",  "max_level": 2,
		"level_costs": [{"coin": 20_000, "mineral": 10_000, "tier": "low"},
		                {"coin": 100_000, "mineral": 50_000, "tier": "mid"}]},
	{"id": "cannon_bloodthirst","name": "嗜血残暴",   "weapon": "cannon",  "max_level": 2,
		"level_costs": [{"coin": 20_000, "mineral": 10_000, "tier": "low"},
		                {"coin": 100_000, "mineral": 50_000, "tier": "mid"}]},
	{"id": "cannon_rush",       "name": "狂飙突进",   "weapon": "cannon",  "max_level": 2,
		"level_costs": [{"coin": 20_000, "mineral": 10_000, "tier": "low"},
		                {"coin": 100_000, "mineral": 50_000, "tier": "mid"}]},
	{"id": "cannon_vengeance", "name": "为了部落",   "weapon": "cannon",  "max_level": 2,
		"level_costs": [{"coin": 20_000, "mineral": 10_000, "tier": "low"},
		                {"coin": 100_000, "mineral": 50_000, "tier": "mid"}]},
	{"id": "railgun_multi",    "name": "多重射击",    "weapon": "railgun", "max_level": 2,
		"level_costs": [{"coin": 20_000, "mineral": 10_000, "tier": "low"},
		                {"coin": 100_000, "mineral": 50_000, "tier": "mid"}]},
	{"id": "railgun_crit",     "name": "命中注定",    "weapon": "railgun", "max_level": 2,
		"level_costs": [{"coin": 20_000, "mineral": 10_000, "tier": "low"},
		                {"coin": 100_000, "mineral": 50_000, "tier": "mid"}]},
	{"id": "railgun_damage",   "name": "一发入魂",    "weapon": "railgun", "max_level": 2,
		"level_costs": [{"coin": 20_000, "mineral": 10_000, "tier": "low"},
		                {"coin": 100_000, "mineral": 50_000, "tier": "mid"}]},
	{"id": "laser_duration",   "name": "高能光束",    "weapon": "laser",   "max_level": 2,
		"level_costs": [{"coin": 20_000, "mineral": 10_000, "tier": "low"},
		                {"coin": 100_000, "mineral": 50_000, "tier": "mid"}]},
	{"id": "laser_width",      "name": "高效射击",    "weapon": "laser",   "max_level": 2,
		"level_costs": [{"coin": 20_000, "mineral": 10_000, "tier": "low"},
		                {"coin": 100_000, "mineral": 50_000, "tier": "mid"}]},
	{"id": "laser_shield",     "name": "护盾中和",    "weapon": "laser",   "max_level": 2,
		"level_costs": [{"coin": 20_000, "mineral": 10_000, "tier": "low"},
		                {"coin": 100_000, "mineral": 50_000, "tier": "mid"}]},
]

const WEAPON_SECTIONS: Array = [
	{"weapon": "missile",  "name": "导弹科技"},
	{"weapon": "cannon",   "name": "加农炮科技"},
	{"weapon": "railgun",  "name": "磁轨炮科技"},
	{"weapon": "laser",    "name": "激光炮科技"},
]

@onready var list_container: VBoxContainer = $Panel/VBox/ResearchScroll/ListVBox
@onready var currency_label: Label = $Panel/VBox/CurrencyBar
@onready var back_btn: Button = $Panel/VBox/BackBtn

func _ready() -> void:
	if back_btn:
		back_btn.pressed.connect(_on_back)
	call_deferred("_deferred_init")

func _deferred_init() -> void:
	_update_currency_display()
	_build_research_list()

func _get_mineral_amount(tier: String) -> int:
	match tier:
		"low":  return GameState.minerals_low
		"mid":  return GameState.minerals_mid
		"high": return GameState.minerals_high
	return 0

func _deduct_mineral(tier: String, amount: int) -> void:
	match tier:
		"low":  GameState.minerals_low -= amount
		"mid":  GameState.minerals_mid -= amount
		"high": GameState.minerals_high -= amount

func _can_afford_research(cost: Dictionary) -> bool:
	if GameState.star_coin < cost["coin"]:
		return false
	var mineral_amount = _get_mineral_amount(cost["tier"])
	return mineral_amount >= cost["mineral"]

func _build_research_list() -> void:
	if not list_container:
		return
	for child in list_container.get_children():
		child.queue_free()

	for section in WEAPON_SECTIONS:
		var section_header = Label.new()
		section_header.text = section["name"]
		section_header.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		section_header.add_theme_font_size_override("font_size", 20)
		list_container.add_child(section_header)

		var section_items = RESEARCH_DATA.filter(func(d): return d["weapon"] == section["weapon"])
		for item in section_items:
			var row = _create_research_row(item)
			list_container.add_child(row)

func _create_research_row(item: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size.y = 48

	var name_label = Label.new()
	name_label.text = item["name"]
	name_label.custom_minimum_size.x = 120
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	row.add_child(name_label)

	var current_level = GameState.research_progress.get(item["id"], 0)
	var max_level = item["max_level"]
	var level_label = Label.new()
	level_label.text = "科研 Lv.%d/%d" % [current_level, max_level]
	level_label.custom_minimum_size.x = 130
	level_label.add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.3) if current_level >= max_level else Color(0.6, 0.8, 1.0))
	row.add_child(level_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	if current_level < max_level:
		var cost = item["level_costs"][current_level]
		var cost_label = Label.new()
		cost_label.text = "星币 %s | 矿物 %s %s" % [
			_str_num(cost["coin"]),
			_str_num(cost["mineral"]),
			_str_tier_name(cost["tier"])]
		cost_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
		row.add_child(cost_label)

		var btn = Button.new()
		var can_afford = _can_afford_research(cost)
		btn.text = "科研" if can_afford else "资源不足"
		btn.disabled = not can_afford
		btn.pressed.connect(_on_research_clicked.bind(item["id"]))
		row.add_child(btn)
	else:
		var done_label = Label.new()
		done_label.text = "[ 已完成 ]"
		done_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		row.add_child(done_label)

	return row

func _str_num(n: int) -> String:
	if n >= 1_000_000:
		return "%dM" % (n / 1_000_000)
	elif n >= 1_000:
		return "%dK" % (n / 1_000)
	return str(n)

func _str_tier_name(tier: String) -> String:
	match tier:
		"low":  return "低矿"
		"mid":  return "中矿"
		"high": return "高矿"
	return tier

func _on_research_clicked(research_id: String) -> void:
	var item = RESEARCH_DATA.filter(func(d): return d["id"] == research_id)
	if item.is_empty():
		return
	item = item[0]

	var current_level = GameState.research_progress.get(research_id, 0)
	if current_level >= item["max_level"]:
		return

	var cost = item["level_costs"][current_level]
	if not _can_afford_research(cost):
		return

	GameState.star_coin -= cost["coin"]
	_deduct_mineral(cost["tier"], cost["mineral"])
	GameState.research_progress[research_id] = current_level + 1

	GameState.auto_save()
	_update_currency_display()
	_build_research_list()

func _update_currency_display() -> void:
	if currency_label:
		currency_label.text = "星币: %s  |  矿物: %s低 / %s中 / %s高" % [
			_str_num(GameState.star_coin),
			_str_num(GameState.minerals_low),
			_str_num(GameState.minerals_mid),
			_str_num(GameState.minerals_high)]

func _on_back() -> void:
	get_parent().close_all_panels()
