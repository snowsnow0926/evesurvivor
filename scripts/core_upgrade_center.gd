extends Control

const CoreDefinitions = preload("res://resources/core_definitions.gd")

@onready var list_container: VBoxContainer = $Panel/VBox/CoreScroll/ListVBox
@onready var currency_label: Label = $Panel/VBox/CurrencyBar
@onready var back_btn: Button = $Panel/VBox/BackBtn
@onready var core_title: Label = $Panel/VBox/CoreTitle

var _selected_core_id: String = ""


func _ready() -> void:
	visible = false
	if back_btn:
		back_btn.pressed.connect(_on_back)
	call_deferred("_deferred_init")


func _deferred_init() -> void:
	_refresh()


func _refresh() -> void:
	_update_currency_display()
	_build_core_list()


func open() -> void:
	visible = true
	z_index = 50
	_refresh()


func close() -> void:
	visible = false
	get_parent().close_all_panels()


func _update_currency_display() -> void:
	if currency_label:
		currency_label.text = "星币: %s  |  矿物: %s低 / %s中 / %s高" % [
			_str_num(GameState.star_coin),
			_str_num(GameState.minerals_low),
			_str_num(GameState.minerals_mid),
			_str_num(GameState.minerals_high)]


func _build_core_list() -> void:
	if not list_container:
		return
	for child in list_container.get_children():
		child.queue_free()

	var summary = CoreEquipManager.get_all_cores_summary()
	if summary.is_empty():
		var lbl = Label.new()
		lbl.text = "(无可用核心)"
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		list_container.add_child(lbl)
		return

	# 标题行：核心名称
	var header = HBoxContainer.new()
	header.custom_minimum_size.y = 36

	var name_lbl = Label.new()
	name_lbl.text = "核心"
	name_lbl.custom_minimum_size.x = 140
	name_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	name_lbl.add_theme_font_size_override("font_size", 18)
	header.add_child(name_lbl)

	var level_lbl = Label.new()
	level_lbl.text = "等级"
	level_lbl.custom_minimum_size.x = 80
	level_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	level_lbl.add_theme_font_size_override("font_size", 18)
	header.add_child(level_lbl)

	var status_lbl = Label.new()
	status_lbl.text = "状态"
	status_lbl.custom_minimum_size.x = 100
	status_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	status_lbl.add_theme_font_size_override("font_size", 18)
	header.add_child(status_lbl)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	var action_lbl = Label.new()
	action_lbl.text = "操作"
	action_lbl.custom_minimum_size.x = 200
	action_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	action_lbl.add_theme_font_size_override("font_size", 18)
	header.add_child(action_lbl)

	list_container.add_child(header)

	for core_info in summary:
		var row = _create_core_row(core_info)
		list_container.add_child(row)


func _create_core_row(core_info: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size.y = 48

	var core_id = core_info["core_id"]
	var is_unlocked = core_info["is_unlocked"]
	var is_equipped = core_info["is_equipped"]
	var display_name = core_info["display_name"]
	var cd = CoreEquipManager.get_core_data(core_id)

	# 计算总等级
	var total_level = 0
	var max_display = 6
	if cd:
		for sid in cd.skill_levels:
			total_level += cd.skill_levels[sid]
		max_display = CoreEquipManager.get_skill_max_level(core_id, cd.skill_levels.keys()[0]) if not cd.skill_levels.is_empty() else 6

	# 名称
	var name_lbl = Label.new()
	name_lbl.text = display_name
	name_lbl.custom_minimum_size.x = 140
	name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	row.add_child(name_lbl)

	# 等级
	var level_lbl = Label.new()
	level_lbl.text = "Lv.%d/%d" % [total_level, max_display * 5]  # 简化显示
	level_lbl.custom_minimum_size.x = 80
	level_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	row.add_child(level_lbl)

	# 状态
	var status_lbl = Label.new()
	if not is_unlocked:
		status_lbl.text = "[未解锁]"
		status_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	elif is_equipped:
		status_lbl.text = "[已装备]"
		status_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	else:
		status_lbl.text = "[仓库]"
		status_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.4))
	row.add_child(status_lbl)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	# 操作按钮
	if is_unlocked:
		if is_equipped:
			var btn = Button.new()
			btn.text = "查看详情"
			btn.pressed.connect(_on_view_detail.bind(core_id))
			row.add_child(btn)
		else:
			var btn = Button.new()
			btn.text = "安装"
			btn.pressed.connect(_on_install_core.bind(core_id))
			row.add_child(btn)
	else:
		var lbl = Label.new()
		lbl.text = "[ 锁定 ]"
		lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		row.add_child(lbl)

	return row


func _on_install_core(core_id: String) -> void:
	CoreEquipManager.equip_core(core_id)
	GameState.auto_save()
	_refresh()


func _on_view_detail(core_id: String) -> void:
	_selected_core_id = core_id
	_show_skill_detail(core_id)


func _show_skill_detail(core_id: String) -> void:
	# 清空列表，改为显示词条详情
	if not list_container:
		return
	for child in list_container.get_children():
		child.queue_free()

	# 返回按钮
	var back_row = HBoxContainer.new()
	back_row.custom_minimum_size.y = 36
	var back_btn = Button.new()
	back_btn.text = "< 返回核心列表"
	back_btn.pressed.connect(func(): _build_core_list())
	back_row.add_child(back_btn)
	list_container.add_child(back_row)

	# 核心名
	var title = Label.new()
	title.text = CoreEquipManager.get_display_name(core_id) + " - 词条升级"
	title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	title.add_theme_font_size_override("font_size", 20)
	title.custom_minimum_size.y = 36
	list_container.add_child(title)

	# 表头
	var header = HBoxContainer.new()
	header.custom_minimum_size.y = 30
	var h_name = Label.new()
	h_name.text = "词条"
	h_name.custom_minimum_size.x = 140
	h_name.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	h_name.add_theme_font_size_override("font_size", 16)
	header.add_child(h_name)

	var h_level = Label.new()
	h_level.text = "等级"
	h_level.custom_minimum_size.x = 100
	h_level.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	h_level.add_theme_font_size_override("font_size", 16)
	header.add_child(h_level)

	var h_action = Label.new()
	h_action.text = "局外升级"
	h_action.custom_minimum_size.x = 300
	h_action.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	h_action.add_theme_font_size_override("font_size", 16)
	header.add_child(h_action)
	list_container.add_child(header)

	# 词条列表
	var skills = CoreEquipManager.get_core_skill_detail(core_id)
	for skill in skills:
		var row = _create_skill_row(core_id, skill)
		list_container.add_child(row)


func _create_skill_row(core_id: String, skill: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size.y = 44

	var skill_id = skill["skill_id"]
	var name = skill["name"]
	var current = skill["current_level"]
	var max_lvl = skill["max_level"]
	var color = skill["color"]
	var is_race = skill["is_race_skill"]

	# 词条名（带颜色）
	var name_lbl = Label.new()
	name_lbl.text = ("[种族] " if is_race else "[通用] ") + name
	name_lbl.custom_minimum_size.x = 140
	name_lbl.add_theme_color_override("font_color", color)
	row.add_child(name_lbl)

	# 等级
	var level_lbl = Label.new()
	level_lbl.text = "Lv.%d/%d" % [current, max_lvl]
	level_lbl.custom_minimum_size.x = 100
	if current >= max_lvl:
		level_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	else:
		level_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	row.add_child(level_lbl)

	# 升级按钮（局外升级）
	if current < max_lvl:
		var cost_info = CoreEquipManager.get_extra_level_cost(core_id, skill_id)
		if not cost_info.is_empty():
			var coin_cost = cost_info.get("coin", 0)
			var mineral_cost = cost_info.get("mineral", 0)
			var tier = cost_info.get("tier", "low")
			var can_afford = _can_afford(coin_cost, mineral_cost, tier)

			var cost_lbl = Label.new()
			cost_lbl.text = "星币 %s | 矿物 %s %s" % [_str_num(coin_cost), _str_num(mineral_cost), _str_tier_name(tier)]
			cost_lbl.custom_minimum_size.x = 180
			cost_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5) if can_afford else Color(0.6, 0.3, 0.3))
			row.add_child(cost_lbl)

			var btn = Button.new()
			btn.text = "升级" if can_afford else "资源不足"
			btn.disabled = not can_afford
			btn.pressed.connect(_on_upgrade_skill.bind(core_id, skill_id, coin_cost, mineral_cost, tier))
			row.add_child(btn)
		else:
			var lbl = Label.new()
			lbl.text = "[ 已满级 ]"
			lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
			row.add_child(lbl)
	else:
		var lbl = Label.new()
		lbl.text = "[ 满级 ]"
		lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		row.add_child(lbl)

	return row


func _can_afford(coin: int, mineral: int, tier: String) -> bool:
	if GameState.star_coin < coin:
		return false
	match tier:
		"low":  return GameState.minerals_low >= mineral
		"mid":  return GameState.minerals_mid >= mineral
		"high": return GameState.minerals_high >= mineral
	return false


func _get_mineral_amount(tier: String) -> int:
	match tier:
		"low":  return GameState.minerals_low
		"mid":  return GameState.minerals_mid
		"high": return GameState.minerals_high
	return 0


func _on_upgrade_skill(core_id: String, skill_id: String, coin_cost: int, mineral_cost: int, tier: String) -> void:
	var success = CoreEquipManager.upgrade_skill_extra(core_id, skill_id, coin_cost, mineral_cost, tier)
	if success:
		GameState.auto_save()
		_show_skill_detail(core_id)
	else:
		_refresh()


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


func _on_back() -> void:
	close()
