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

const BUILDING_DATA: Array[Dictionary] = [
	{
		"id": "repair",
		"name": "维修站",
		"desc": "修复战斗中受损的舰船，恢复全部耐久度",
		"icon": "res://assets/base/icons/icon_repair.png",
		"method": "_show_repair",
	},
	{
		"id": "crafting",
		"name": "装备合成",
		"desc": "将两件相同品质的装备合成为更高品质",
		"icon": "res://assets/base/icons/icon_crafting.png",
		"method": "_show_crafting",
	},
	{
		"id": "research",
		"name": "科研中心",
		"desc": "解锁并升级各类型武器的科技",
		"icon": "res://assets/base/icons/icon_research.png",
		"method": "_show_research",
	},
	{
		"id": "shop",
		"name": "武器商店",
		"desc": "购买或出售武器与装甲",
		"icon": "res://assets/base/icons/icon_shop.png",
		"method": "_show_shop",
	},
	{
		"id": "warehouse",
		"name": "物品仓库",
		"desc": "管理仓库中的所有装备",
		"icon": "res://assets/base/icons/icon_warehouse.png",
		"method": "_show_warehouse",
	},
	{
		"id": "shipyard",
		"name": "造船厂",
		"desc": "解锁新战舰，扩展武器与装甲槽位",
		"icon": "res://assets/base/icons/icon_shipyard.png",
		"method": "_show_shipyard",
	},
	{
		"id": "storage",
		"name": "星港",
		"desc": "选择本次出战的主力舰船",
		"icon": "res://assets/base/icons/icon_storage.png",
		"method": "_show_storage",
	},
]

func _ready() -> void:
	SoundManager.play_music("base")
	_build_building_cards()
	building_grid.add_theme_constant_override("h_separation", 32)
	building_grid.add_theme_constant_override("v_separation", 32)
	_bind_buttons()
	_update_currency_display()
	base_pause_menu = find_child("BasePauseMenu", true, false)
	_connect_save_ui_signals()
	if GameState.player_name.is_empty() or GameState.first_run:
		get_tree().change_scene_to_file("res://scenes/CharacterCreate.tscn")

func _build_building_cards() -> void:
	for data in BUILDING_DATA:
		var card := _create_building_card(data)
		building_grid.add_child(card)

func _create_building_card(data: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 192)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 48)
	panel.add_child(hbox)

	var icon_tex := load(data["icon"])
	var icon: Control
	if icon_tex:
		icon = TextureRect.new()
		icon.texture = icon_tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(128, 128)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		icon = _create_placeholder_icon()
	hbox.add_child(icon)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	hbox.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = data["name"]
	name_lbl.add_theme_font_size_override("font_size", 36)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = data["desc"]
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 26)
	desc_lbl.custom_minimum_size = Vector2(480, 0)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vbox.add_child(desc_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var arrow := Label.new()
	arrow.text = ">"
	arrow.add_theme_font_size_override("font_size", 44)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(arrow)

	panel.gui_input.connect(_make_card_input_handler(data["method"]))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	return panel

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
	_switch_panel(crafting_panel)
	if crafting_panel.has_method("_build_inventory"):
		crafting_panel._build_inventory()

func _show_warehouse() -> void:
	var panel := _get_or_create_panel(&"warehouse") as Control
	_switch_panel(panel)
	if panel and panel.has_method("_build_all"):
		panel._build_all()

func _show_research() -> void:
	var panel := _get_or_create_panel(&"research") as Control
	_switch_panel(panel)

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
