extends Control

const SAVE_SLOTS := 3

signal save_loaded(slot_idx: int)
signal new_game_requested
signal back_requested

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
		"star_coin": cfg.get_value("progress", "star_coin", 0),
		"highest_level": cfg.get_value("progress", "highest_level", 1),
	}

func _create_slot_row(slot_idx: int, data: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 48)

	var label = Label.new()
	label.text = "存档位 %d" % (slot_idx + 1)
	label.custom_minimum_size = Vector2(100, 0)
	row.add_child(label)

	var info_label = Label.new()
	if data.is_empty():
		info_label.text = "[ 空 ]"
		info_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	else:
		var name = data.get("player_name", "")
		var coin = data.get("star_coin", 0)
		var lvl = data.get("highest_level", 1)
		var date = data.get("saved_at", "")
		info_label.text = "%s  |  星币:%d  |  最高等级:%d  |  %s" % [name, coin, lvl, date]
		info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	row.add_child(info_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var load_btn = Button.new()
	load_btn.text = "读取"
	load_btn.disabled = data.is_empty()
	load_btn.pressed.connect(_on_load_slot.bind(slot_idx))
	row.add_child(load_btn)
	slot_buttons.append(load_btn)

	return row

func _on_load_slot(slot_idx: int) -> void:
	SoundManager.play_sfx("button_click")
	GameState.current_save_slot = slot_idx
	GameState.load_save_slot(slot_idx)
	emit_signal("save_loaded", slot_idx)
	get_tree().change_scene_to_file("res://scenes/BaseScene.tscn")

func _on_new_game() -> void:
	SoundManager.play_sfx("button_click")
	GameState.reset_for_new_run()
	emit_signal("new_game_requested")
	get_tree().change_scene_to_file("res://scenes/CharacterCreate.tscn")

func _on_back() -> void:
	SoundManager.play_sfx("button_click")
	emit_signal("back_requested")
	visible = false
