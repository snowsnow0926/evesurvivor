extends Control

const EquipmentData = preload("res://resources/equipment_data.gd")
const WeaponData = preload("res://resources/weapon_data.gd")

signal pause_toggled
signal retreat_requested
signal self_destruct_requested

@onready var panel: Panel = $Panel
@onready var continue_btn: Button = $Panel/VBox/ContinueBtn
@onready var settings_btn: Button = $Panel/VBox/SettingsBtn
@onready var retreat_btn: Button = $Panel/VBox/RetreatBtn
@onready var sfx_toggle_btn: Button = $Panel/VBox/SFXToggleBtn
@onready var self_destruct_btn: Button = $Panel/VBox/SelfDestructBtn
@onready var loot_scroll: ScrollContainer = $Panel/VBox/LootScroll
@onready var loot_container: VBoxContainer = $Panel/VBox/LootScroll/LootContainer
@onready var loot_section_label: Label = $Panel/VBox/LootSectionLabel

var game_manager: Node2D
var is_open: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	is_open = false
	_connect_buttons()
	print("[PauseMenu] ready, process_mode=", process_mode)

func _connect_buttons() -> void:
	if continue_btn:
		continue_btn.pressed.connect(_on_continue_pressed)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	if retreat_btn:
		retreat_btn.pressed.connect(_on_retreat_pressed)
	if sfx_toggle_btn:
		sfx_toggle_btn.pressed.connect(_on_sfx_toggle_pressed)
	if self_destruct_btn:
		self_destruct_btn.pressed.connect(_on_self_destruct_pressed)

func open_menu(gm: Node2D) -> void:
	game_manager = gm
	visible = true
	is_open = true
	print("[PauseMenu] opened, visible=", visible, " process_mode=", process_mode)
	if game_manager:
		game_manager.is_paused = true
		get_tree().paused = true
		_build_pause_loot_list()
	_notify_hud_paused(true)

func _notify_hud_paused(paused: bool) -> void:
	var gs = get_tree().get_first_node_in_group("game_scene") as Node
	if not gs:
		return
	var hud = gs.get_node_or_null("UIRoot/HUD")
	if hud and hud.has_method("set_paused_state"):
		hud.set_paused_state(paused)

func _on_continue_pressed() -> void:
	SoundManager.play_sfx("button_click")
	print("[PauseMenu] continue pressed")
	close_menu()

func _on_settings_pressed() -> void:
	SoundManager.play_sfx("button_click")
	var scene: PackedScene = load("res://scenes/SettingsUI.tscn")
	var ui: Control = scene.instantiate()
	add_child(ui)

func close_menu() -> void:
	visible = false
	is_open = false
	if game_manager and is_instance_valid(game_manager):
		game_manager.is_paused = false
	get_tree().paused = false
	_notify_hud_paused(false)

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
		var name_str := item.get("name", "") as String
		var quality_color := EquipmentData.get_quality_color(item.get("quality", 0))
		if name_str.is_empty():
			if item.get("type") == "weapon":
				var wid: int = item.get("weapon_id", 0)
				var wd := WeaponData.get_weapon(wid)
				name_str = wd.display_name if wd else "?"
			else:
				var aid: int = item.get("armor_id", 0)
				name_str = EquipmentData.get_armor_name(aid)
		var label := Label.new()
		label.text = "[%s] %s" % [type_str, name_str]
		label.add_theme_color_override("font_color", quality_color)
		row.add_child(label)
		loot_container.add_child(row)

func _on_sfx_toggle_pressed() -> void:
	SoundManager.play_sfx("button_click")
	var scene: PackedScene = load("res://scenes/SettingsUI.tscn")
	var ui: Control = scene.instantiate()
	add_child(ui)

func _on_retreat_pressed() -> void:
	print("[PauseMenu] retreat pressed, is_game_over=", game_manager.is_game_over if game_manager else "no gm")
	if game_manager and is_instance_valid(game_manager):
		game_manager.on_retreat()
	# don't close menu here — game_ended signal will trigger settlement screen

func _on_self_destruct_pressed() -> void:
	print("[PauseMenu] self_destruct pressed")
	if game_manager and is_instance_valid(game_manager):
		game_manager.on_self_destruct()
	# don't close menu here — game_ended signal will trigger transition
