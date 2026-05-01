extends Control

@onready var repair_btn: Button = $NavPanel/VBox/RepairBtn
@onready var crafting_btn: Button = $NavPanel/VBox/CraftingBtn
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
@onready var shop_panel: Control = $ShopPanel
@onready var warehouse_panel: Control = $WarehousePanel
@onready var shipyard_panel: Control = $ShipyardPanel

var base_pause_menu: Control
var current_panel: Control = null
var warning_timer: float = 0.0

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
	if warehouse_panel and is_instance_valid(warehouse_panel):
		warehouse_panel.visible = true
		current_panel = warehouse_panel
		if warehouse_panel.has_method("_build_all"):
			warehouse_panel._build_all()

func _show_shop() -> void:
	_switch_panel(shop_panel)

func _show_shipyard() -> void:
	_switch_panel(shipyard_panel)

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
	for p in [repair_panel, crafting_panel, storage_panel, shop_panel, warehouse_panel, shipyard_panel]:
		if p:
			p.visible = false

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
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")

func _show_no_weapon_warning() -> void:
	no_weapon_warning.visible = true
	warning_timer = 3.0
