extends Control

@onready var ship_list: VBoxContainer = $Panel/VBox/ShipList
@onready var detail_label: Label = $Panel/VBox/DetailLabel
@onready var repair_btn: Button = $Panel/VBox/RepairBtn
@onready var back_btn: Button = $Panel/VBox/BackBtn

var current_ship: ShipData = null

func _ready() -> void:
	if repair_btn:
		repair_btn.pressed.connect(_on_repair_pressed)
	if back_btn:
		back_btn.pressed.connect(_on_back)
	_build_ship_list()

func _build_ship_list() -> void:
	for child in ship_list.get_children():
		child.queue_free()

	var ships = ShipData.get_all_ships()
	for ship in ships:
		var row = HBoxContainer.new()
		var name_label = Label.new()
		name_label.text = ship.display_name
		name_label.custom_minimum_size.x = 120
		row.add_child(name_label)

		var status_label = Label.new()
		var is_this_damaged = _is_ship_damaged(ship)
		var is_this_ship = _is_current_ship(ship)
		status_label.text = "(已损坏)" if is_this_damaged else ("(当前舰船)" if is_this_ship else "(完好)")
		status_label.add_theme_color_override("font_color",
			Color(1, 0.3, 0.3) if is_this_damaged else Color(0.3, 1, 0.3))
		row.add_child(status_label)

		var cost_label = Label.new()
		cost_label.text = "%d 星币" % ship.repair_cost
		row.add_child(cost_label)

		var btn = Button.new()
		btn.text = "维修" if is_this_damaged else ("使用" if not is_this_ship else "当前")
		btn.disabled = (not is_this_damaged and is_this_ship) or (not is_this_damaged and not is_this_ship)
		btn.pressed.connect(_on_select_ship.bind(ship))
		row.add_child(btn)

		ship_list.add_child(row)

func _is_ship_damaged(ship: ShipData) -> bool:
	return GameState.ship_damaged and _is_current_ship(ship)

func _is_current_ship(ship: ShipData) -> bool:
	return GameState.selected_ship_id == ship.ship_id

func _on_select_ship(ship: ShipData) -> void:
	current_ship = ship
	detail_label.text = "%s\n维修费用: %d 星币\n当前星币: %d" % [
		ship.display_name, ship.repair_cost, GameState.star_coin]
	if repair_btn:
		repair_btn.disabled = not GameState.ship_damaged or GameState.star_coin < ship.repair_cost

func _on_repair_pressed() -> void:
	if not current_ship:
		return
	if GameState.star_coin >= current_ship.repair_cost:
		GameState.star_coin -= current_ship.repair_cost
		GameState.ship_damaged = false
		_build_ship_list()
		detail_label.text = "维修完成！"
	else:
		detail_label.text = "星币不足！"

func _on_back() -> void:
	get_parent().close_all_panels()
