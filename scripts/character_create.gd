extends Control

const ShipData = preload("res://resources/ship_data.gd")
const CoreEntry = preload("res://resources/core_entry.gd")
const CoreDefinitions = preload("res://resources/core_definitions.gd")

@onready var race_grid: GridContainer = $Panel/VBox/RaceScroll/RaceGrid
@onready var name_edit: LineEdit = $Panel/VBox/NameRow/NameEdit
@onready var confirm_btn: Button = $Panel/VBox/BtnRow/ConfirmBtn
@onready var back_btn: Button = $Panel/VBox/BtnRow/BackBtn

const RACE_PORTRAIT_PATHS: Dictionary = {
	RaceData.RaceID.HUMAN: "res://assets/races/human_portrait.png",
	RaceData.RaceID.ORC: "res://assets/races/orc_portrait.png",
	RaceData.RaceID.PLANT: "res://assets/races/plant_portrait.png",
	RaceData.RaceID.SILICON: "res://assets/races/silicon_portrait.png",
}

var selected_race_id: RaceData.RaceID = RaceData.RaceID.HUMAN
var race_buttons: Array = []

func _ready() -> void:
	# 为 PanelContainer 设置默认样式，防止 add_theme_style_override 时 rp_style 为 null
	var panel = $Panel as PanelContainer
	if panel:
		var default_style = StyleBoxFlat.new()
		default_style.bg_color = Color(0.08, 0.08, 0.16, 0.95)
		default_style.set_border_width_all(1)
		default_style.border_color = Color(0.3, 0.3, 0.5, 0.3)
		default_style.set_corner_radius_all(8)
		panel.add_theme_stylebox_override("panel", default_style)
	_build_race_cards()
	_select_race(RaceData.RaceID.HUMAN)
	confirm_btn.pressed.connect(_on_confirm)
	back_btn.pressed.connect(_on_back)
	_update_confirm_button()

func _build_race_cards() -> void:
	for child in race_grid.get_children():
		child.queue_free()
	race_buttons.clear()

	var playable_races = [
		RaceData.RaceID.HUMAN,
		RaceData.RaceID.ORC,
		RaceData.RaceID.PLANT,
		RaceData.RaceID.SILICON,
	]

	for race_id in playable_races:
		var card = _create_race_card(race_id)
		race_grid.add_child(card)

func _create_race_card(race_id: RaceData.RaceID) -> Control:
	var race = RaceData.get_race(race_id)

	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND
	card.size_flags_vertical = Control.SIZE_EXPAND
	card.custom_minimum_size = Vector2(420, 0)

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.08, 0.08, 0.16, 0.95)
	style_normal.set_border_width_all(2)
	style_normal.border_color = Color(0.3, 0.3, 0.5)
	style_normal.set_corner_radius_all(8)
	card.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.12, 0.14, 0.24, 0.95)
	style_hover.set_border_width_all(2)
	style_hover.border_color = Color(0.5, 0.5, 0.8)
	style_hover.set_corner_radius_all(8)

	var style_selected = StyleBoxFlat.new()
	style_selected.bg_color = Color(0.1, 0.16, 0.32, 0.95)
	style_selected.set_border_width_all(3)
	style_selected.border_color = Color(0.4, 0.7, 1.0)
	style_selected.set_corner_radius_all(8)

	var outer_vbox = VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 8)
	card.add_child(outer_vbox)

	# 顶部标题
	var title = Label.new()
	title.text = race.display_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	outer_vbox.add_child(title)

	# 横向布局：左侧立绘 + 右侧详情
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	outer_vbox.add_child(hbox)

	# 左侧：种族立绘
	var portrait_placeholder = ColorRect.new()
	portrait_placeholder.custom_minimum_size = Vector2(200, 0)
	portrait_placeholder.color = Color(0.05, 0.05, 0.1, 1.0)
	hbox.add_child(portrait_placeholder)

	var portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(200, 0)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var portrait_path = RACE_PORTRAIT_PATHS.get(race_id, "")
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
		portrait_placeholder.queue_free()
		hbox.add_child(portrait)
	else:
		portrait.queue_free()
		hbox.add_child(portrait_placeholder)

	# 右侧：详情区
	var detail_vbox = VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 6)
	hbox.add_child(detail_vbox)

	# 属性：两行，第一行 HP/护盾/移速，第二行 闪避/暴击/倍率
	var attrs_line1 = Label.new()
	attrs_line1.text = "HP: %.0f  护盾: %.0f  移速: %.0f" % [race.base_hp, race.shield_max, race.move_speed]
	attrs_line1.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85))
	attrs_line1.add_theme_font_size_override("font_size", 14)
	detail_vbox.add_child(attrs_line1)

	var attrs_line2 = Label.new()
	attrs_line2.text = "闪避: %.0f%%  暴击: %.0f%%  倍率: %.1fx" % [
		race.dodge_rate * 100,
		race.crit_rate * 100,
		race.crit_mult,
	]
	attrs_line2.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85))
	attrs_line2.add_theme_font_size_override("font_size", 14)
	detail_vbox.add_child(attrs_line2)

	# 分隔
	var sep1 = HSeparator.new()
	sep1.set("theme_override_constants/separation", 4)
	detail_vbox.add_child(sep1)

	# 默认核心
	var core_id = CoreRegistry.get_core_id_by_race(race.race_key)
	var core_name = ""
	if not core_id.is_empty():
		var entry_ref = CoreRegistry.get_core_entry(core_id)
		core_name = entry_ref.core_name_zh if entry_ref else (core_id + "核心")
	var core_label = Label.new()
	core_label.text = "默认核心: %s" % core_name
	core_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	core_label.add_theme_font_size_override("font_size", 14)
	detail_vbox.add_child(core_label)

	# 核心技能
	if not core_id.is_empty():
		var entry_ref = CoreRegistry.get_core_entry(core_id)
		if entry_ref:
			var skill_lines: Array = []
			for skill_id in entry_ref.race_skills:
				var sname = CoreDefinitions.get_skill_name(skill_id)
				skill_lines.append("%s Lv.1" % sname)
			for skill_id in entry_ref.universal_skills:
				var sname = CoreDefinitions.get_skill_name(skill_id)
				skill_lines.append("%s Lv.0" % sname)
			var skills_label = Label.new()
			skills_label.text = "核心技能：%s" % " / ".join(skill_lines)
			skills_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85))
			skills_label.add_theme_font_size_override("font_size", 12)
			detail_vbox.add_child(skills_label)

	# 天赋下方加弹性 spacer，推选择按钮到底部
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND
	detail_vbox.add_child(spacer)

	# 选择按钮
	var btn = Button.new()
	btn.flat = true
	btn.custom_minimum_size = Vector2(0, 36)
	btn.text = "选择"
	btn.pressed.connect(_on_race_card_selected.bind(race_id, card))
	detail_vbox.add_child(btn)

	card.set_meta("race_id", race_id)
	card.set_meta("style_normal", style_normal)
	card.set_meta("style_hover", style_hover)
	card.set_meta("style_selected", style_selected)
	card.set_meta("button", btn)

	card.gui_input.connect(_on_card_gui_input.bind(card))
	card.mouse_entered.connect(_on_card_mouse_enter.bind(card))
	card.mouse_exited.connect(_on_card_mouse_exit.bind(card))

	race_buttons.append(card)
	return card

func _on_card_gui_input(event: InputEvent, card: Control) -> void:
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var btn: Button = card.get_meta("button") as Button
			if btn and not btn.disabled:
				btn.emit_signal("pressed")

func _on_race_card_selected(race_id: RaceData.RaceID, card: Control) -> void:
	SoundManager.play_sfx("button_click")
	_select_race(race_id)

func _select_race(race_id: RaceData.RaceID) -> void:
	selected_race_id = race_id
	for card in race_buttons:
		var card_race_id = card.get_meta("race_id") as RaceData.RaceID
		if card_race_id == race_id:
			var sel_style = card.get_meta("style_selected") as StyleBoxFlat
			if sel_style:
				card.add_theme_stylebox_override("normal", sel_style)
			else:
				push_warning("[CharacterCreate] Missing style_selected for race card")
			var btn = card.get_meta("button") as Button
			if btn:
				btn.text = "已选择"
				btn.disabled = true
		else:
			var norm_style = card.get_meta("style_normal") as StyleBoxFlat
			if norm_style:
				card.add_theme_stylebox_override("normal", norm_style)
			var btn = card.get_meta("button") as Button
			if btn:
				btn.text = "选择"
				btn.disabled = false
	_update_confirm_button()

func _on_card_mouse_enter(card: Control) -> void:
	var card_race_id = card.get_meta("race_id") as RaceData.RaceID
	if card_race_id != selected_race_id:
		var hover_style = card.get_meta("style_hover") as StyleBoxFlat
		if hover_style:
			card.add_theme_stylebox_override("normal", hover_style)

func _on_card_mouse_exit(card: Control) -> void:
	var card_race_id = card.get_meta("race_id") as RaceData.RaceID
	if card_race_id != selected_race_id:
		var norm_style = card.get_meta("style_normal") as StyleBoxFlat
		if norm_style:
			card.add_theme_stylebox_override("normal", norm_style)

func _update_confirm_button() -> void:
	confirm_btn.disabled = false

func _on_confirm() -> void:
	SoundManager.play_sfx("button_click")
	GameState.selected_race_id = selected_race_id
	var name = name_edit.text.strip_edges()
	if name.is_empty():
		name = RaceData.get_race(selected_race_id).display_name + "号舰"
	GameState.player_name = name
	GameState.star_coin = 10000000
	GameState.minerals_low = 200000
	GameState.minerals_mid = 200000
	GameState.minerals_high = 200000
	GameState.selected_ship_id = ShipData.ShipID.FRIGATE
	GameState.first_run = false

	# 解锁并装备该种族的核心（存档前必须做，否则仓库/升级中心看不到）
	var race = RaceData.get_race(selected_race_id)
	CoreEquipManager.equip_starting_core(race.race_key)

	var slot = GameState.pending_new_game_slot if GameState.pending_new_game_slot >= 0 else GameState.SLOT_AUTO
	GameState.current_save_slot = slot
	GameState.pending_new_game_slot = -1
	GameState.save_save_slot(slot)
	get_tree().change_scene_to_file("res://scenes/BaseScene.tscn")

func _on_back() -> void:
	SoundManager.play_sfx("button_click")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
