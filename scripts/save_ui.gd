extends Control

const SAVE_SLOTS := 3

signal save_loaded(slot_idx: int)
signal new_game_requested
signal back_requested
signal save_requested(slot_idx: int)

@onready var slots_container: VBoxContainer = $Panel/VBox/SlotsContainer
@onready var back_btn: Button = $Panel/VBox/BtnRow/BackBtn
@onready var new_game_btn: Button = $Panel/VBox/BtnRow/NewGameBtn

var slot_buttons: Array[Button] = []
var _has_save: bool = false

func _ready() -> void:
	_populate_slots()
	back_btn.pressed.connect(_on_back)
	new_game_btn.pressed.connect(_on_new_game)

func _populate_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()
	slot_buttons.clear()
	_has_save = false

	for i in range(SAVE_SLOTS):
		var slot_data = _load_slot_info(i)
		var row = _create_slot_row(i, slot_data)
		slots_container.add_child(row)
		if slot_data != null:
			_has_save = true

	if _has_save:
		new_game_btn.text = "新建游戏 (覆盖存档)"
		new_game_btn.disabled = false
	else:
		new_game_btn.text = "新建游戏"
		new_game_btn.disabled = false

func _load_slot_info(slot_idx: int) -> Dictionary:
	var path = "user://save_slot_%d.cfg" % slot_idx
	if not FileAccess.file_exists(path):
		return {}
	var cfg = ConfigFile.new()
	var err = cfg.load(path)
	if err != OK:
		return {}
	return {
		"exists": true,
		"saved_at": cfg.get_value("meta", "saved_at", ""),
		"player_name": cfg.get_value("player", "player_name", ""),
		"selected_race_id": cfg.get_value("player", "selected_race_id", 0),
		"selected_ship_id": cfg.get_value("player", "selected_ship_id", 1),
		"star_coin": cfg.get_value("progress", "star_coin", 0),
		"minerals_low": cfg.get_value("progress", "minerals_low", 0),
		"minerals_mid": cfg.get_value("progress", "minerals_mid", 0),
		"minerals_high": cfg.get_value("progress", "minerals_high", 0),
		"total_kills": cfg.get_value("progress", "total_kills", 0),
		"total_deaths": cfg.get_value("progress", "total_deaths", 0),
		"highest_level": cfg.get_value("progress", "highest_level", 1),
		"ship_damaged": cfg.get_value("progress", "ship_damaged", false),
		"first_run": cfg.get_value("progress", "first_run", true),
		"unlocked_stages": cfg.get_value("progress", "unlocked_stages", []),
		"stage_first_complete": cfg.get_value("progress", "stage_first_complete", []),
	}

func _create_slot_row(slot_idx: int, data: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 56)

	var label = Label.new()
	label.text = "存档位 %d" % (slot_idx + 1)
	label.custom_minimum_size = Vector2(80, 0)
	row.add_child(label)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var info_line1 = Label.new()
	info_line1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if data.is_empty():
		info_line1.text = "[ 空 ]"
		info_line1.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	else:
		var name = data.get("player_name", "")
		var coin = data.get("star_coin", 0)
		var lvl = data.get("highest_level", 1)
		var kills = data.get("total_kills", 0)
		var stages = data.get("unlocked_stages", [])
		var stage_count = stages.size() if stages is Array else 0
		info_line1.text = "玩家: %s  |  星币: %d  |  最高等级: %d  |  击杀: %d  |  已解锁关卡: %d" % [
			name if name != "" else "(未命名)", coin, lvl, kills, stage_count]
		info_line1.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_vbox.add_child(info_line1)

	var info_line2 = Label.new()
	info_line2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if data.is_empty():
		info_line2.text = ""
	else:
		var min_low = data.get("minerals_low", 0)
		var min_mid = data.get("minerals_mid", 0)
		var min_high = data.get("minerals_high", 0)
		var ship_dmg = data.get("ship_damaged", false)
		var date = data.get("saved_at", "")
		info_line2.text = "矿物: %d低/%d中/%d高  |  舰船: %s  |  %s" % [
			min_low, min_mid, min_high,
			"损坏" if ship_dmg else "完好",
			date]
		info_line2.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info_vbox.add_child(info_line2)

	row.add_child(info_vbox)

	var btn_vbox = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 4)

	var load_btn = Button.new()
	load_btn.text = "读取"
	load_btn.custom_minimum_size = Vector2(70, 28)
	load_btn.disabled = data.is_empty()
	load_btn.pressed.connect(_on_load_slot.bind(slot_idx))
	btn_vbox.add_child(load_btn)
	slot_buttons.append(load_btn)

	var save_btn = Button.new()
	save_btn.text = "保存"
	save_btn.custom_minimum_size = Vector2(70, 28)
	save_btn.pressed.connect(_on_save_slot.bind(slot_idx))
	btn_vbox.add_child(save_btn)

	row.add_child(btn_vbox)

	return row

func _on_load_slot(slot_idx: int) -> void:
	SoundManager.play_sfx("button_click")
	GameState.current_save_slot = slot_idx
	GameState.load_save_slot(slot_idx)
	emit_signal("save_loaded", slot_idx)
	get_tree().change_scene_to_file("res://scenes/BaseScene.tscn")

func _on_save_slot(slot_idx: int) -> void:
	SoundManager.play_sfx("button_click")
	GameState.current_save_slot = slot_idx
	GameState.save_save_slot(slot_idx)
	_populate_slots()

func _on_new_game() -> void:
	SoundManager.play_sfx("button_click")
	GameState.reset_for_new_run()
	emit_signal("new_game_requested")
	get_tree().change_scene_to_file("res://scenes/CharacterCreate.tscn")

func _on_back() -> void:
	SoundManager.play_sfx("button_click")
	emit_signal("back_requested")
	visible = false
