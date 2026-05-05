extends Control

@onready var ship_list: VBoxContainer = $Panel/VBox/ShipList
@onready var equip_detail: Label = $Panel/VBox/EquipDetail
@onready var back_btn: Button = $Panel/VBox/BackBtn

var current_ship: ShipData = null

func _ready() -> void:
	if back_btn:
		back_btn.pressed.connect(_on_back)
	_build_ship_list()

func _build_ship_list() -> void:
	for child in ship_list.get_children():
		child.queue_free()

	var ships = ShipData.get_all_ships()
	for ship in ships:
		var row = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = ship.display_name
		row.add_child(name_lbl)

		var status_lbl = Label.new()
		var is_current = _is_current_ship(ship)
		var is_unlocked = ship.is_unlocked or GameState.unlocked_ships.has(int(ship.ship_id))
		status_lbl.text = "(当前)" if is_current else ("(未解锁)" if not is_unlocked else "(未使用)")
		status_lbl.add_theme_color_override("font_color",
			Color(1, 1, 0.3) if is_current else
			(Color(0.5, 0.5, 0.5) if not is_unlocked else Color(0.3, 1, 0.3)))
		row.add_child(status_lbl)

		var btn = Button.new()
		if not is_unlocked:
			btn.text = "解锁(%d星币)" % ship.unlock_cost
			btn.pressed.connect(_try_unlock_ship.bind(ship))
		else:
			btn.text = "选择"
			btn.pressed.connect(_select_ship.bind(ship))
		row.add_child(btn)
		ship_list.add_child(row)

func _is_current_ship(ship: ShipData) -> bool:
	return GameState.selected_ship_id == ship.ship_id

func _try_unlock_ship(ship: ShipData) -> void:
	if GameState.star_coin >= ship.unlock_cost:
		GameState.star_coin -= ship.unlock_cost
		if not GameState.unlocked_ships.has(int(ship.ship_id)):
			GameState.unlocked_ships.append(ship.ship_id)
		equip_detail.text = "%s 已解锁！" % ship.display_name
		_build_ship_list()

func _select_ship(ship: ShipData) -> void:
	current_ship = ship
	GameState.selected_ship_id = ship.ship_id
	equip_detail.text = ship.display_name
	_build_ship_list()

func _on_back() -> void:
	get_parent().close_all_panels()
