extends Control

const EquipmentData = preload("res://resources/equipment_data.gd")
const WeaponData = preload("res://resources/weapon_data.gd")

signal pause_toggled
signal retreat_requested
signal self_destruct_requested

@onready var panel: Panel = $Panel
@onready var continue_btn: Button = $Panel/VBox/ContinueBtn
@onready var retreat_btn: Button = $Panel/VBox/RetreatBtn
@onready var self_destruct_btn: Button = $Panel/VBox/SelfDestructBtn
@onready var loot_scroll: ScrollContainer = $Panel/VBox/LootScroll
@onready var loot_container: VBoxContainer = $Panel/VBox/LootScroll/LootContainer
@onready var loot_section_label: Label = $Panel/VBox/LootSectionLabel

var game_manager: Node2D
var is_open: bool = false

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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	is_open = false
	_connect_buttons()

func _connect_buttons() -> void:
	if continue_btn:
		continue_btn.pressed.connect(_on_continue_pressed)
	if retreat_btn:
		retreat_btn.pressed.connect(_on_retreat_pressed)
	if self_destruct_btn:
		self_destruct_btn.pressed.connect(_on_self_destruct_pressed)

func open_menu(gm: Node2D) -> void:
	game_manager = gm
	visible = true
	is_open = true
	if game_manager:
		game_manager.is_paused = true
		get_tree().paused = true
		_build_pause_loot_list()

func _on_continue_pressed() -> void:
	SoundManager.play_sfx("button_click")
	close_menu()

func close_menu(p_keep_paused: bool = false) -> void:
	visible = false
	is_open = false
	if not p_keep_paused:
		if game_manager and is_instance_valid(game_manager):
			game_manager.is_paused = false
		get_tree().paused = false

func _build_pause_loot_list() -> void:
	if loot_section_label:
		loot_section_label.visible = false
	if loot_scroll:
		loot_scroll.visible = false
	if not loot_container:
		return
	for child in loot_container.get_children():
		child.queue_free()
	if not game_manager or not is_instance_valid(game_manager):
		return
	var loot: Array = game_manager.get_session_loot()
	if loot.size() == 0:
		return
	if loot_section_label:
		loot_section_label.visible = true
		loot_section_label.text = "本次获得物品:"
	if loot_scroll:
		loot_scroll.visible = true
	for item: Dictionary in loot:
		var row := HBoxContainer.new()
		var type_str := "武器" if item.get("type") == "weapon" else "防具"
		var name_str := ""
		var quality_color := Color.WHITE
		if item.get("type") == "weapon":
			var wid: int = item.get("weapon_id", 0)
			if wid == 0:
				var sid: int = item.get("shop_item_id", 0)
				wid = _shop_item_id_to_weapon_id(sid)
			var wd := WeaponData.get_weapon(wid)
			name_str = wd.display_name if wd else item.get("name", "?")
			quality_color = EquipmentData.get_quality_color(item.get("quality", 0))
		else:
			var aid: int = item.get("armor_id", 0)
			name_str = EquipmentData.get_armor_name(aid) if aid >= 0 else item.get("name", "?")
			quality_color = EquipmentData.get_quality_color(item.get("quality", 0))
		var label := Label.new()
		label.text = "[%s] %s" % [type_str, name_str]
		label.add_theme_color_override("font_color", quality_color)
		row.add_child(label)
		loot_container.add_child(row)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and is_open:
		SoundManager.play_sfx("button_click")
		close_menu()

func _on_retreat_pressed() -> void:
	SoundManager.play_sfx("retreat_success")
	if game_manager and is_instance_valid(game_manager):
		game_manager.on_retreat()
	close_menu(true)
	retreat_requested.emit()

func _on_self_destruct_pressed() -> void:
	SoundManager.play_sfx("self_destruct")
	if game_manager and is_instance_valid(game_manager):
		game_manager.on_self_destruct()
	close_menu(true)
	self_destruct_requested.emit()
