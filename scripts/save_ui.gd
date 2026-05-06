extends Control

const SAVE_SLOTS := 3

enum Mode { LOAD, SAVE }

signal save_loaded(slot_idx: int)
signal save_completed(slot_idx: int)
signal new_game_requested
signal back_requested

@onready var title_label: Label = $Panel/VBox/Title
@onready var slots_container: VBoxContainer = $Panel/VBox/SlotsContainer
@onready var btn_row: HBoxContainer = $Panel/VBox/BtnRow
@onready var back_btn: Button = $Panel/VBox/BtnRow/BackBtn
@onready var new_game_btn: Button = $Panel/VBox/BtnRow/NewGameBtn
@onready var confirm_btn: Button = $Panel/VBox/BtnRow/ConfirmBtn

var slot_buttons: Array[Button] = []
var _mode: Mode = Mode.LOAD
var _selected_slot: int = -1
var _has_save: bool = false

func _ready() -> void:
	if back_btn:
		back_btn.pressed.connect(_on_back)
	if new_game_btn:
		new_game_btn.pressed.connect(_on_new_game)
	if confirm_btn:
		confirm_btn.pressed.connect(_on_confirm_pressed)
	_populate_slots()

func open_as(mode: Mode) -> void:
	_mode = mode
	# 从 current_save_slot 恢复 _selected_slot，这样重新打开时保留上次选择的槽位
	_selected_slot = GameState.current_save_slot if GameState.current_save_slot >= 0 else -1
	if _mode == Mode.LOAD:
		title_label.text = "读取存档"
		confirm_btn.visible = false
		new_game_btn.visible = true
		new_game_btn.text = "新建游戏"
	else:
		title_label.text = "保存存档"
		confirm_btn.visible = false
		new_game_btn.visible = false
	_populate_slots()
	visible = true

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

	if _mode == Mode.LOAD:
		if _has_save:
			new_game_btn.text = "新建游戏 (覆盖存档)"
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

	if _mode == Mode.LOAD:
		var load_btn = Button.new()
		load_btn.text = "读取"
		load_btn.disabled = data.is_empty()
		load_btn.pressed.connect(_on_load_slot.bind(slot_idx))
		row.add_child(load_btn)
		slot_buttons.append(load_btn)
	else:
		var save_btn = Button.new()
		save_btn.text = "保存"
		save_btn.pressed.connect(_on_select_slot.bind(slot_idx))
		row.add_child(save_btn)
		slot_buttons.append(save_btn)

	return row

func _on_select_slot(slot_idx: int) -> void:
	SoundManager.play_sfx("button_click")
	_selected_slot = slot_idx
	_slot_row_apply_selection(slot_idx)
	confirm_btn.visible = true

func _slot_row_apply_selection(selected: int) -> void:
	for i in range(slot_buttons.size()):
		var btn = slot_buttons[i]
		if i == selected:
			btn.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
			btn.add_theme_color_override("font_hover_color", Color(0.4, 1.0, 0.4))
		else:
			btn.remove_theme_color_override("font_color")
			btn.remove_theme_color_override("font_hover_color")

func _on_load_slot(slot_idx: int) -> void:
	SoundManager.play_sfx("button_click")
	# load_save_slot 会先设置 current_save_slot 再加载，BaseScene._ready() 就能读到正确值
	GameState.load_save_slot(slot_idx)
	emit_signal("save_loaded", slot_idx)
	get_tree().change_scene_to_file("res://scenes/BaseScene.tscn")

func _on_confirm_pressed() -> void:
	if _selected_slot < 0:
		return
	SoundManager.play_sfx("button_click")
	GameState.save_save_slot(_selected_slot)
	emit_signal("save_completed", _selected_slot)
	visible = false
	_populate_slots()

func _on_new_game() -> void:
	SoundManager.play_sfx("button_click")
	GameState.reset_for_new_run()
	emit_signal("new_game_requested")
	get_tree().change_scene_to_file("res://scenes/CharacterCreate.tscn")

func _on_back() -> void:
	SoundManager.play_sfx("button_click")
	confirm_btn.visible = false
	_selected_slot = -1
	emit_signal("back_requested")
	visible = false
