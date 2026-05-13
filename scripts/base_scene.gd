extends Control

@onready var start_battle_btn: Button = $BottomPanel/StartBattleBtn
@onready var coin_label: Label = $Header/HBox/CurrencyBar/CoinLabel
@onready var minerals_label: Label = $Header/HBox/CurrencyBar/MineralsLabel
@onready var no_weapon_warning: Label = $NoWeaponWarning
@onready var building_grid: GridContainer = $BuildingGrid

@onready var repair_panel: Control = $RepairPanel
@onready var crafting_panel: Control = $CraftingPanel
@onready var storage_panel: Control = $StoragePanel
@onready var save_ui: Control = $SaveUI

@onready var building_repair: Area2D = $BuildingLayer/BuildingNode_repair
@onready var building_crafting: Area2D = $BuildingLayer/BuildingNode_crafting
@onready var building_research: Area2D = $BuildingLayer/BuildingNode_research
@onready var building_shop: Area2D = $BuildingLayer/BuildingNode_shop
@onready var building_warehouse: Area2D = $BuildingLayer/BuildingNode_warehouse
@onready var building_shipyard: Area2D = $BuildingLayer/BuildingNode_shipyard
@onready var building_storage: Area2D = $BuildingLayer/BuildingNode_storage

var base_pause_menu: Control
var current_panel: Control = null
var warning_timer: float = 0.0

var _shop_panel: Control
var _warehouse_panel: Control
var _shipyard_panel: Control
var _research_panel: Control

var _building_nodes: Dictionary = {}
var _hover_tween: Dictionary = {}
var _hovered_building: String = ""

const _PANEL_SCENES := {
	"shop": "res://scenes/ShopUI.tscn",
	"warehouse": "res://scenes/WarehouseUI.tscn",
	"shipyard": "res://scenes/ShipyardUI.tscn",
	"research": "res://scenes/CoreUpgradeCenter.tscn",
}

const BUILDING_DATA: Array[Dictionary] = [
	{
		"id": "repair",
		"name": "维修站",
		"desc": "修复战斗中受损的舰船，恢复全部耐久度",
		"icon": "res://assets/base/icons/icon_repair.png",
		"sprite": "res://assets/base/buildings/building_repair.png",
		"method": "_show_repair",
	},
	{
		"id": "crafting",
		"name": "装备合成",
		"desc": "将两件相同品质的装备合成为更高品质",
		"icon": "res://assets/base/icons/icon_crafting.png",
		"sprite": "res://assets/base/buildings/building_crafting.png",
		"method": "_show_crafting",
	},
	{
		"id": "research",
		"name": "核心升级中心",
		"desc": "升级核心词条，扩展各武器等级上限",
		"icon": "res://assets/base/icons/icon_research.png",
		"sprite": "res://assets/base/buildings/building_research.png",
		"method": "_show_research",
	},
	{
		"id": "shop",
		"name": "武器商店",
		"desc": "购买或出售武器与装甲",
		"icon": "res://assets/base/icons/icon_shop.png",
		"sprite": "res://assets/base/buildings/building_shop.png",
		"method": "_show_shop",
	},
	{
		"id": "warehouse",
		"name": "物品仓库",
		"desc": "管理仓库中的所有装备",
		"icon": "res://assets/base/icons/icon_warehouse.png",
		"sprite": "res://assets/base/buildings/building_warehouse.png",
		"method": "_show_warehouse",
	},
	{
		"id": "shipyard",
		"name": "造船厂",
		"desc": "解锁新战舰，扩展武器与装甲槽位",
		"icon": "res://assets/base/icons/icon_shipyard.png",
		"sprite": "res://assets/base/buildings/building_shipyard.png",
		"method": "_show_shipyard",
	},
	{
		"id": "storage",
		"name": "星港",
		"desc": "选择本次出战的主力舰船",
		"icon": "res://assets/base/icons/icon_storage.png",
		"sprite": "res://assets/base/buildings/building_dock.png",
		"method": "_show_storage",
	},
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SoundManager.play_music("base")
	building_grid.visible = false
	_setup_building_nodes()
	_bind_buttons()
	_update_currency_display()
	base_pause_menu = find_child("BasePauseMenu", true, false)
	_connect_save_ui_signals()
	if GameState.player_name.is_empty() or GameState.first_run:
		get_tree().change_scene_to_file("res://scenes/CharacterCreate.tscn")

func _setup_building_nodes() -> void:
	var id_to_node := {
		"repair":    building_repair,
		"crafting":  building_crafting,
		"research":  building_research,
		"shop":      building_shop,
		"warehouse": building_warehouse,
		"shipyard":  building_shipyard,
		"storage":   building_storage,
	}
	var id_to_data := {}
	for d in BUILDING_DATA:
		id_to_data[d["id"]] = d

	for bid in id_to_node:
		var area: Area2D = id_to_node[bid]
		if area == null:
			continue
		var data: Dictionary = id_to_data.get(bid, {})
		if data.is_empty():
			continue

		var shape := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape == null:
			shape = CollisionShape2D.new()
			shape.name = "CollisionShape2D"
			area.add_child(shape)
		var circle := CircleShape2D.new()
		circle.radius = 120.0
		shape.shape = circle

		var sprite := area.get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			sprite.centered = true
			sprite.offset = Vector2.ZERO

		_building_nodes[bid] = area

func _input(event: InputEvent) -> void:
	if current_panel and is_instance_valid(current_panel):
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_check_building_click()

func _check_building_click() -> void:
	var world_mouse := get_global_mouse_position()
	for bid in _building_nodes:
		var area: Area2D = _building_nodes[bid]
		if area == null or not is_instance_valid(area):
			continue
		var diff := world_mouse - area.get_global_position()
		if diff.length() <= 120.0:
			for d in BUILDING_DATA:
				if d["id"] == bid:
					call(d["method"])
					break
			return

func _set_building_hover(area: Area2D, on: bool) -> void:
	if area == null or not is_instance_valid(area):
		return
	var sprite := area.get_node_or_null("Sprite2D") as Sprite2D
	var hover_sprite := area.get_node_or_null("HoverOverlay") as Sprite2D

	if is_instance_valid(_hover_tween.get(area)):
		_hover_tween[area].kill()

	var tw := create_tween().set_parallel(true)
	_hover_tween[area] = tw

	if on:
		if hover_sprite:
			hover_sprite.modulate.a = 0.4
		if sprite:
			tw.tween_property(sprite, "modulate", Color(1.2, 1.3, 1.4, 1.0), 0.15)
	else:
		if hover_sprite:
			tw.tween_property(hover_sprite, "modulate:a", 0.0, 0.15)
		if sprite:
			tw.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)

func _create_placeholder_icon() -> Control:
	var rect := ColorRect.new()
	rect.custom_minimum_size = Vector2(128, 128)
	rect.color = Color(0.15, 0.2, 0.35, 1.0)
	return rect

func _make_card_input_handler(method_name: String) -> Callable:
	return func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				call(method_name)

func _connect_save_ui_signals() -> void:
	if save_ui and save_ui.has_signal("save_completed"):
		save_ui.save_completed.connect(_on_save_completed)
	if save_ui and save_ui.has_signal("back_requested"):
		save_ui.back_requested.connect(_on_save_ui_back)

func _on_save_completed(slot_idx: int) -> void:
	var popup := AcceptDialog.new()
	popup.dialog_text = "存档已保存到位置 %d" % (slot_idx + 1)
	get_tree().current_scene.add_child(popup)
	popup.popup_centered()

func _on_save_ui_back() -> void:
	pass

func _bind_buttons() -> void:
	if start_battle_btn:
		start_battle_btn.pressed.connect(_on_start_battle)

func _update_currency_display() -> void:
	if coin_label:
		coin_label.text = "星币: %d" % GameState.star_coin
	if minerals_label:
		minerals_label.text = "矿物: %d低/%d中/%d高" % [
			GameState.minerals_low, GameState.minerals_mid, GameState.minerals_high]

func _process(delta: float) -> void:
	if current_panel and is_instance_valid(current_panel):
		_update_currency_display()
		if no_weapon_warning.visible:
			warning_timer -= delta
			if warning_timer <= 0:
				no_weapon_warning.visible = false
		if Input.is_action_just_pressed("pause"):
			close_all_panels()
		return

	_update_currency_display()
	if no_weapon_warning.visible:
		warning_timer -= delta
		if warning_timer <= 0:
			no_weapon_warning.visible = false
	if Input.is_action_just_pressed("pause"):
		if base_pause_menu and base_pause_menu.visible:
			base_pause_menu.close_menu()
		else:
			base_pause_menu.open_menu()
		return

	var current_hover := ""

	for bid in _building_nodes:
		var area: Area2D = _building_nodes[bid]
		if area == null or not is_instance_valid(area):
			continue
		var diff := get_global_mouse_position() - area.get_global_position()
		if diff.length() <= 120.0:
			current_hover = bid
			break

	if current_hover != _hovered_building:
		if _hovered_building != "" and _building_nodes.has(_hovered_building):
			_set_building_hover(_building_nodes[_hovered_building], false)
		if current_hover != "":
			_set_building_hover(_building_nodes[current_hover], true)
		_hovered_building = current_hover

func _any_panel_visible() -> bool:
	if current_panel and is_instance_valid(current_panel) and current_panel.visible:
		return true
	if repair_panel and repair_panel.visible:
		return true
	if crafting_panel and crafting_panel.visible:
		return true
	if storage_panel and storage_panel.visible:
		return true
	if _shop_panel and _shop_panel.visible:
		return true
	if _warehouse_panel and _warehouse_panel.visible:
		return true
	if _shipyard_panel and _shipyard_panel.visible:
		return true
	if _research_panel and _research_panel.visible:
		return true
	if base_pause_menu and base_pause_menu.visible:
		return true
	return false

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
	_switch_panel(crafting_panel)
	if crafting_panel.has_method("_build_inventory"):
		crafting_panel._build_inventory()

func _show_warehouse() -> void:
	var panel := _get_or_create_panel(&"warehouse") as Control
	_switch_panel(panel)
	if panel and panel.has_method("_build_all"):
		panel._build_all()

func _show_research() -> void:
	var panel = _get_or_create_panel(&"research") as Control
	_switch_panel(panel)
	if panel and panel.has_method("open"):
		panel.open()

func _show_shop() -> void:
	var panel := _get_or_create_panel(&"shop") as Control
	_switch_panel(panel)

func _show_shipyard() -> void:
	var panel := _get_or_create_panel(&"shipyard") as Control
	_switch_panel(panel)

func _show_storage() -> void:
	_switch_panel(storage_panel)
	if storage_panel and storage_panel.has_method("_build_ship_list"):
		storage_panel._build_ship_list()

func _switch_panel(panel: Control) -> void:
	if current_panel and is_instance_valid(current_panel):
		current_panel.visible = false
		_set_panel_opaque(current_panel, false)
	if panel and is_instance_valid(panel):
		panel.visible = true
		_set_panel_opaque(panel, true)
		current_panel = panel

func _set_panel_opaque(panel: Control, opaque: bool) -> void:
	var p = panel.find_child("Panel", false, false)
	if p == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.97) if opaque else Color(0, 0, 0, 0)
	style.set_border_width_all(2)
	style.border_color = Color(0.2, 0.3, 0.5, 1.0)
	style.set_corner_radius_all(8)
	if p is PanelContainer:
		p.add_theme_stylebox_override("panel", style)
	elif p is Panel:
		p.add_theme_stylebox_override("panel", style)

func close_all_panels() -> void:
	if current_panel and is_instance_valid(current_panel):
		current_panel.visible = false
		_set_panel_opaque(current_panel, false)
		current_panel = null
	for p in [repair_panel, crafting_panel, storage_panel]:
		if p:
			p.visible = false
			_set_panel_opaque(p, false)
	if _shop_panel:
		_shop_panel.visible = false
		_set_panel_opaque(_shop_panel, false)
	if _warehouse_panel:
		_warehouse_panel.visible = false
		_set_panel_opaque(_warehouse_panel, false)
	if _shipyard_panel:
		_shipyard_panel.visible = false
		_set_panel_opaque(_shipyard_panel, false)
	if _research_panel:
		_research_panel.visible = false
		_set_panel_opaque(_research_panel, false)

func _on_start_battle() -> void:
	var ship = ShipData.get_ship(GameState.selected_ship_id)
	if ship == null:
		ship = ShipData.get_ship(ShipData.ShipID.FRIGATE)
	var ship_id = int(ship.ship_id)
	var equipped = GameState.equipped_weapons.get(ship_id)
	var has_weapon := false
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

func open_save_ui_for_save() -> void:
	if save_ui:
		save_ui.open_as(save_ui.Mode.SAVE)

func open_save_ui_for_load() -> void:
	if save_ui:
		save_ui.open_as(save_ui.Mode.LOAD)
