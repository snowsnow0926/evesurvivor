extends Control

const SAVE_SLOTS := 3

signal slot_selected(slot_idx: int, is_save: bool)
signal cancelled

@onready var slots_container: VBoxContainer = $Panel/VBox/SlotsContainer
@onready var title_label: Label = $Panel/VBox/Title
@onready var action_btn: Button = $Panel/VBox/ActionBtn
@onready var cancel_btn: Button = $Panel/VBox/CancelBtn

var slot_buttons: Array[Button] = []
var _save_mode: bool = true
var _selected_slot: int = -1

func _ready() -> void:
	action_btn.pressed.connect(_on_action_pressed)
	cancel_btn.pressed.connect(_on_cancel)
	if not action_btn.pressed.is_connected(_on_action_pressed):
		action_btn.pressed.connect(_on_action_pressed)
	if not cancel_btn.pressed.is_connected(_on_cancel):
		cancel_btn.pressed.connect(_on_cancel)

func open(save_mode: bool) -> void:
	_save_mode = save_mode
	_selected_slot = -1
	_update_title()
	_populate_slots()
	visible = true

func _update_title() -> void:
	if title_label:
		title_label.text = "保存游戏" if _save_mode else "读取存档"

func _populate_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()
	slot_buttons.clear()

	for i in range(SAVE_SLOTS):
		var slot_data = _load_slot_info(i)
		var row = _create_slot_row(i, slot_data)
		slots_container.add_child(row)

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
	row.custom_minimum_size = Vector2(0, 52)
	row.add_theme_constant_override("separation", 8)

	var slot_btn = Button.new()
	slot_btn.custom_minimum_size = Vector2(120, 44)
	slot_btn.toggle_mode = true
	slot_btn.set_pressed_no_signal(false)
	slot_btn.pressed.connect(_on_slot_btn_pressed.bind(slot_idx, slot_btn))

	var name = data.get("player_name", "") if not data.is_empty() else ""
	if data.is_empty():
		slot_btn.text = "存档位 %d" % (slot_idx + 1)
		slot_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	else:
		slot_btn.text = "存档位 %d" % (slot_idx + 1)
		slot_btn.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	row.add_child(slot_btn)
	slot_buttons.append(slot_btn)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var info_line1 = Label.new()
	info_line1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if data.is_empty():
		info_line1.text = "[ 空 ]"
		info_line1.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	else:
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
		var first_run = data.get("first_run", true)
		var date = data.get("saved_at", "")
		info_line2.text = "矿物: %d低/%d中/%d高  |  舰船: %s  |  %s" % [
			min_low, min_mid, min_high,
			"损坏" if ship_dmg else "完好",
			date]
		info_line2.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info_vbox.add_child(info_line2)

	row.add_child(info_vbox)

	return row

func _on_slot_btn_pressed(slot_idx: int, btn: Button) -> void:
	SoundManager.play_sfx("button_click")
	for other_btn in slot_buttons:
		if other_btn != btn:
			other_btn.set_pressed_no_signal(false)
	_selected_slot = slot_idx

func _on_action_pressed() -> void:
	if _selected_slot < 0:
		var popup = AcceptDialog.new()
		popup.dialog_text = "请先选择一个存档位"
		get_tree().current_scene.add_child(popup)
		popup.popup_centered()
		return
	SoundManager.play_sfx("button_click")
	visible = false
	slot_selected.emit(_selected_slot, _save_mode)

func _on_cancel() -> void:
	SoundManager.play_sfx("button_click")
	visible = false
	cancelled.emit()
