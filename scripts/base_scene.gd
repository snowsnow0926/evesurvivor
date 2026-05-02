extends Control

@onready var repair_btn: Button = $NavPanel/VBox/RepairBtn
@onready var crafting_btn: Button = $NavPanel/VBox/CraftingBtn
@onready var research_btn: Button = $NavPanel/VBox/ResearchBtn
@onready var shop_btn: Button = $NavPanel/VBox/ShopBtn
@onready var warehouse_btn: Button = $NavPanel/VBox/WarehouseBtn
@onready var shipyard_btn: Button = $NavPanel/VBox/ShipyardBtn
@onready var storage_btn: Button = $NavPanel/VBox/StorageBtn
@onready var start_battle_btn: Button = $NavPanel/VBox/StartBattleBtn
@onready var coin_label: Label = $Header/HBox/CurrencyBar/CoinLabel
@onready var minerals_label: Label = $Header/HBox/CurrencyBar/MineralsLabel
@onready var no_weapon_warning: Label = $NoWeaponWarning

@onready var repair_panel: Control = $RepairPanel
@onready var crafting_panel: Control = $CraftingPanel
@onready var storage_panel: Control = $StoragePanel

var base_pause_menu: Control
var current_panel: Control = null
var warning_timer: float = 0.0

var _shop_panel: Control
var _warehouse_panel: Control
var _shipyard_panel: Control
var _research_panel: Control

const _PANEL_SCENES := {
	"shop": "res://scenes/ShopUI.tscn",
	"warehouse": "res://scenes/WarehouseUI.tscn",
	"shipyard": "res://scenes/ShipyardUI.tscn",
	"research": "res://scenes/ResearchCenterUI.tscn",
}

func _ready() -> void:
	SoundManager.play_music("base")
	_bind_buttons()
	_update_currency_display()
	base_pause_menu = find_child("BasePauseMenu", true, false)
	if GameState.player_name.is_empty() or GameState.first_run:
		get_tree().change_scene_to_file("res://scenes/CharacterCreate.tscn")

func _bind_buttons() -> void:
	if repair_btn:
		repair_btn.pressed.connect(_show_repair)
	if crafting_btn:
		crafting_btn.pressed.connect(_show_crafting)
	if research_btn:
		research_btn.pressed.connect(_show_research)
	if shop_btn:
		shop_btn.pressed.connect(_show_shop)
	if warehouse_btn:
		warehouse_btn.pressed.connect(_show_warehouse)
	if shipyard_btn:
		shipyard_btn.pressed.connect(_show_shipyard)
	if storage_btn:
		storage_btn.pressed.connect(_show_storage)
	if start_battle_btn:
		start_battle_btn.pressed.connect(_on_start_battle)

func _update_currency_display() -> void:
	if coin_label:
		coin_label.text = "星币: %d" % GameState.star_coin
	if minerals_label:
		minerals_label.text = "矿物: %d低/%d中/%d高" % [
			GameState.minerals_low, GameState.minerals_mid, GameState.minerals_high]

func _process(delta: float) -> void:
	_update_currency_display()
	if no_weapon_warning.visible:
		warning_timer -= delta
		if warning_timer <= 0:
			no_weapon_warning.visible = false
	if Input.is_action_just_pressed("pause"):
		if base_pause_menu and base_pause_menu.visible:
			base_pause_menu.close_menu()
		else:
			if base_pause_menu:
				base_pause_menu.open_menu()

func _get_or_create_panel(key: StringName) -> Control:
	match key:
		&"shop":
			if not _shop_panel:
				_shop_panel = _instantiate_panel(_PANEL_SCENES["shop"])
				add_child(_shop_panel)
				_shop_panel.visible = false
			return _shop_panel
		&"warehouse":
			if not _warehouse_panel:
				_warehouse_panel = _instantiate_panel(_PANEL_SCENES["warehouse"])
				add_child(_warehouse_panel)
				_warehouse_panel.visible = false
			return _warehouse_panel
		&"shipyard":
			if not _shipyard_panel:
				_shipyard_panel = _instantiate_panel(_PANEL_SCENES["shipyard"])
				add_child(_shipyard_panel)
				_shipyard_panel.visible = false
			return _shipyard_panel
		&"research":
			if not _research_panel:
				_research_panel = _instantiate_panel(_PANEL_SCENES["research"])
				add_child(_research_panel)
				_research_panel.visible = false
			return _research_panel
	return null

func _instantiate_panel(scene_path: String) -> Control:
	var scene_res := load(scene_path)
	if scene_res == null:
		push_error("[BaseScene] Failed to load scene: " + scene_path)
		return null
	var instance: Node = scene_res.instantiate()
	if instance == null:
		push_error("[BaseScene] Failed to instantiate scene: " + scene_path)
		return null
	return instance as Control

func _show_repair() -> void:
	_switch_panel(repair_panel)

func _show_crafting() -> void:
	if current_panel and is_instance_valid(current_panel):
		current_panel.visible = false
	if crafting_panel and is_instance_valid(crafting_panel):
		crafting_panel.visible = true
		current_panel = crafting_panel
		if crafting_panel.has_method("_build_inventory"):
			crafting_panel._build_inventory()

func _show_warehouse() -> void:
	if current_panel and is_instance_valid(current_panel):
		current_panel.visible = false
	var panel := _get_or_create_panel(&"warehouse") as Control
	if panel and is_instance_valid(panel):
		panel.visible = true
		current_panel = panel
		if panel.has_method("_build_all"):
			panel._build_all()

func _show_research() -> void:
	if current_panel and is_instance_valid(current_panel):
		current_panel.visible = false
	var panel := _get_or_create_panel(&"research") as Control
	if panel and is_instance_valid(panel):
		panel.visible = true
		current_panel = panel

func _show_shop() -> void:
	if current_panel and is_instance_valid(current_panel):
		current_panel.visible = false
	var panel := _get_or_create_panel(&"shop") as Control
	if panel and is_instance_valid(panel):
		panel.visible = true
		current_panel = panel

func _show_shipyard() -> void:
	if current_panel and is_instance_valid(current_panel):
		current_panel.visible = false
	var panel := _get_or_create_panel(&"shipyard") as Control
	if panel and is_instance_valid(panel):
		panel.visible = true
		current_panel = panel

func _show_storage() -> void:
	_switch_panel(storage_panel)

func _switch_panel(panel: Control) -> void:
	if current_panel and is_instance_valid(current_panel):
		current_panel.visible = false
	if panel and is_instance_valid(panel):
		panel.visible = true
		current_panel = panel

func close_all_panels() -> void:
	if current_panel and is_instance_valid(current_panel):
		current_panel.visible = false
		current_panel = null
	for p in [repair_panel, crafting_panel, storage_panel]:
		if p:
			p.visible = false
	if _shop_panel:
		_shop_panel.visible = false
	if _warehouse_panel:
		_warehouse_panel.visible = false
	if _shipyard_panel:
		_shipyard_panel.visible = false
	if _research_panel:
		_research_panel.visible = false

func _on_start_battle() -> void:
	var ship = ShipData.get_ship(GameState.selected_ship_id)
	if ship == null:
		ship = ShipData.get_ship(ShipData.ShipID.FRIGATE)
	var ship_id = int(ship.ship_id)
	var equipped = GameState.equipped_weapons.get(ship_id)
	var has_weapon = false
	if equipped is Array:
		has_weapon = not equipped.is_empty()
	elif equipped is Dictionary:
		has_weapon = not equipped.is_empty()
	if not has_weapon:
		_show_no_weapon_warning()
		return
	get_tree().change_scene_to_file("res://scenes/ChapterSelectUI.tscn")

func _show_no_weapon_warning() -> void:
	no_weapon_warning.visible = true
	warning_timer = 3.0
