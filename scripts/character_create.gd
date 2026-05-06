extends Control

const ShipData = preload("res://resources/ship_data.gd")

@onready var race_grid: GridContainer = $Panel/VBox/RaceScroll/RaceGrid
@onready var name_edit: LineEdit = $Panel/VBox/NameRow/NameEdit
@onready var confirm_btn: Button = $Panel/VBox/BtnRow/ConfirmBtn
@onready var back_btn: Button = $Panel/VBox/BtnRow/BackBtn

var selected_race_id: RaceData.RaceID = RaceData.RaceID.HUMAN
var race_buttons: Array = []
var _selected_slot: int = 0  # 0-based save slot, default to slot 0 for new games

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
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(200, 260)

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

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	var title = Label.new()
	title.text = race.display_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	vbox.add_child(title)

	var desc_label = Label.new()
	desc_label.text = race.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(180, 60)
	vbox.add_child(desc_label)

	var attrs_label = Label.new()
	attrs_label.text = "HP: %.0f  护盾: %.0f\n移速: %.0f  闪避: %.0f%%\n暴击: %.0f%%  倍率: %.1fx" % [
		race.base_hp,
		race.shield_max,
		race.move_speed,
		race.dodge_rate * 100,
		race.crit_rate * 100,
		race.crit_mult,
	]
	attrs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attrs_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85))
	vbox.add_child(attrs_label)

	var weapon_name = "导弹"
	if "Cannon" in race.base_weapon_scene:
		weapon_name = "加农炮"
	elif "Railgun" in race.base_weapon_scene:
		weapon_name = "磁轨炮"
	elif "Laser" in race.base_weapon_scene:
		weapon_name = "激光炮"
	var weapon_label = Label.new()
	weapon_label.text = "默认武器: %s" % weapon_name
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_label.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	vbox.add_child(weapon_label)

	if race.talents.size() > 0:
		var talent_label = Label.new()
		var talent_lines: Array = []
		for t in race.talents:
			talent_lines.append("[%s]" % t["name"])
		talent_label.text = "\n".join(talent_lines)
		talent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		talent_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		vbox.add_child(talent_label)

	var btn = Button.new()
	btn.flat = true
	btn.custom_minimum_size = Vector2(0, 36)
	btn.text = "选择"
	btn.pressed.connect(_on_race_card_selected.bind(race_id, card))
	vbox.add_child(btn)

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
	# Use the selected slot so BaseScene's _ready() loads the right data
	# 使用 _selected_slot 指定的槽位（由 SaveUI 打开时通过 GameState.current_save_slot 传入）
	GameState.current_save_slot = _selected_slot
	GameState.save_save_slot(_selected_slot)
	get_tree().change_scene_to_file("res://scenes/BaseScene.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
