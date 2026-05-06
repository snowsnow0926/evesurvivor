extends Control

const EquipmentData = preload("res://resources/equipment_data.gd")
const WeaponData = preload("res://resources/weapon_data.gd")
const ShopItemData = preload("res://resources/shop_data.gd")

var settlement_reason: String = ""
var session_kills: int = 0
var session_coin: int = 0
var session_minerals: int = 0
var session_level: int = 1
var earned_coin: int = 0
var earned_minerals: int = 0
var session_loot: Array = []

@onready var result_label: Label = $Panel/VBox/ResultLabel
@onready var result_desc: Label = $Panel/VBox/ResultDesc
@onready var kills_label: Label = $Panel/VBox/StatsGrid/KillsValue
@onready var level_label: Label = $Panel/VBox/StatsGrid/LevelValue
@onready var coin_label: Label = $Panel/VBox/StatsGrid/CoinValue
@onready var minerals_label: Label = $Panel/VBox/StatsGrid/MineralsValue
@onready var earned_coin_label: Label = $Panel/VBox/StatsGrid/EarnedHBox/EarnedCoinValue
@onready var earned_minerals_label: Label = $Panel/VBox/StatsGrid/EarnedMineralsValue
@onready var ship_status_label: Label = $Panel/VBox/ShipStatusLabel
@onready var retry_btn: Button = $Panel/VBox/ButtonsHBox/RetryBtn
@onready var base_btn: Button = $Panel/VBox/ButtonsHBox/BaseBtn
@onready var menu_btn: Button = $Panel/VBox/ButtonsHBox/MenuBtn
@onready var loot_section_label: Label = $Panel/VBox/LootSectionLabel
@onready var loot_scroll: ScrollContainer = $Panel/VBox/LootScroll
@onready var loot_container: VBoxContainer = $Panel/VBox/LootScroll/LootContainer
var loot_slots: Array[HBoxContainer] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_buttons()

	# Initialize loot_slots if not yet done
	if loot_slots.is_empty():
		for i: int in range(5):
			var slot_path := "Panel/VBox/LootScroll/LootContainer/LootSlot%d" % i
			var slot: Node = get_node_or_null(slot_path)
			if slot != null:
				loot_slots.append(slot)
				slot.visible = false

	# Build loot display once slots are ready
	if session_loot.size() > 0:
		_update_display()
		_build_loot_list()

func _connect_buttons() -> void:
	if retry_btn:
		retry_btn.pressed.connect(_on_retry_pressed)
	if base_btn:
		base_btn.pressed.connect(_on_base_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)

func set_settlement_data(reason: String, kills: int, level: int, coin: int, minerals: int, loot: Array = []) -> void:
	settlement_reason = reason
	session_kills = kills
	session_level = level
	session_coin = GameState.star_coin
	session_minerals = GameState.minerals_low + GameState.minerals_mid + GameState.minerals_high

	earned_coin = coin
	earned_minerals = minerals

	session_loot = loot.duplicate(true)

	GameState.last_run_reason = reason

	_update_display()

	# Only build loot list if slots are already initialized, otherwise _ready() will call it
	if loot_slots.size() > 0:
		_build_loot_list()

func _gui_input(event: InputEvent) -> void:
	pass

func _update_display() -> void:
	if result_label:
		match settlement_reason:
			"dead":
				result_label.text = "任务失败"
			"timeout":
				result_label.text = "时间到！"
			"retreat":
				result_label.text = "任务完成"
			"self_destruct":
				result_label.text = "任务中止"
			_:
				result_label.text = "任务完成"

	if result_desc:
		match settlement_reason:
			"dead":
				result_desc.text = "舰船损毁，损失50%%收益"
			"timeout":
				result_desc.text = "时间到！100%%收益"
			"retreat":
				result_desc.text = "撤离成功，100%%收益"
			"self_destruct":
				result_desc.text = "自毁退出，无收益"
			_:
				result_desc.text = ""

	if kills_label:
		kills_label.text = "%d" % session_kills
	if level_label:
		level_label.text = "%d" % session_level
	if coin_label:
		coin_label.text = "%d" % session_coin
	if minerals_label:
		minerals_label.text = "%d" % session_minerals
	if earned_coin_label:
		earned_coin_label.text = "+%d" % earned_coin
	if earned_minerals_label:
		earned_minerals_label.text = "+%d" % earned_minerals

	if ship_status_label:
		if GameState.ship_damaged:
			ship_status_label.text = "舰船损坏 - 维修费: %d 星币" % GameState.get_repair_cost()
			ship_status_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
		else:
			ship_status_label.text = "舰船状态: 良好"
			ship_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1))
	if retry_btn:
		if settlement_reason == "self_destruct":
			retry_btn.text = "重新开始"
			retry_btn.disabled = false
		elif GameState.ship_damaged and GameState.star_coin < GameState.get_repair_cost():
			retry_btn.text = "星币不足"
			retry_btn.disabled = true
		else:
			retry_btn.text = "重新开始"
			retry_btn.disabled = GameState.ship_damaged

func _build_loot_list() -> void:
	# Hide/show section label and scroll container based on loot count
	if loot_section_label:
		loot_section_label.visible = session_loot.size() > 0
	if loot_scroll:
		loot_scroll.visible = session_loot.size() > 0
	
	# First, hide all slots
	for slot in loot_slots:
		slot.visible = false
	
	# Populate slots with loot data
	for i: int in range(mini(session_loot.size(), loot_slots.size())):
		var loot: Dictionary = session_loot[i]
		var slot: HBoxContainer = loot_slots[i]
		var type_label: Label = slot.get_node_or_null("TypeLabel")
		var name_label: Label = slot.get_node_or_null("NameLabel")
		
		if type_label == null or name_label == null:
			continue
		
		# Determine type and name
		var type_str := "武器" if loot.get("type") == "weapon" else "防具"
		var name_str: String = loot.get("name", "")
		if name_str.is_empty() or name_str == "?":
			if loot.get("type") == "weapon":
				var sid: int = loot.get("weapon_id", -1)
				if sid >= 0:
					var shop_item = ShopItemData.get_item(sid)
					name_str = shop_item.display_name if shop_item and not shop_item.display_name.is_empty() else ""
			else:
				var aid: int = loot.get("armor_id", -1)
				name_str = EquipmentData.get_armor_name(aid)
		if name_str.is_empty():
			name_str = "?"
		
		# Apply quality color
		var quality: int = loot.get("quality", 0)
		var quality_color := EquipmentData.get_quality_color(quality)
		
		# Update labels
		type_label.text = "[%s]" % type_str
		name_label.text = name_str
		name_label.add_theme_color_override("font_color", quality_color)
		slot.visible = true

func set_reason(reason: String) -> void:
	settlement_reason = reason
	_update_display()

func _on_retry_pressed() -> void:
	if GameState.ship_damaged:
		if GameState.star_coin >= GameState.get_repair_cost():
			GameState.repair_ship()
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_base_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/BaseScene.tscn")
