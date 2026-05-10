extends Control

@onready var ship_list: VBoxContainer = $Panel/VBox/ShipList
@onready var back_btn: Button = $Panel/VBox/BackBtn

func _ready() -> void:
	if back_btn:
		back_btn.pressed.connect(_on_back)
	_build_ship_list()

func _enter_tree() -> void:
	_build_ship_list()

func _build_ship_list() -> void:
	if not ship_list:
		return
	for child in ship_list.get_children():
		child.queue_free()

	var ships = ShipData.get_all_ships()
	for ship in ships:
		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 48)

		var name_lbl = Label.new()
		name_lbl.text = ship.display_name
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var status_lbl = Label.new()
		var is_current = GameState.selected_ship_id == ship.ship_id
		if is_current:
			status_lbl.text = "[当前]"
			status_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
		elif ship.is_unlocked or GameState.unlocked_ships.has(int(ship.ship_id)):
			status_lbl.text = ""
		else:
			status_lbl.text = "[锁定]"
			status_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		row.add_child(status_lbl)

		var btn = Button.new()
		if is_current:
			btn.text = "已选择"
			btn.disabled = true
		elif not (ship.is_unlocked or GameState.unlocked_ships.has(int(ship.ship_id))):
			btn.text = "未解锁"
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.text = "选择"
			btn.pressed.connect(_select_ship.bind(ship))
		row.add_child(btn)
		ship_list.add_child(row)

func _select_ship(ship: ShipData) -> void:
	if not (ship.is_unlocked or GameState.unlocked_ships.has(int(ship.ship_id))):
		return
	GameState.selected_ship_id = ship.ship_id
	GameState.auto_save()
	_build_ship_list()

func _on_back() -> void:
	get_parent().close_all_panels()
