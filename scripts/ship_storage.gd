extends Control

@onready var ship_list: VBoxContainer = $Panel/VBox/ShipList
@onready var equip_detail: Label = $Panel/VBox/EquipDetail
@onready var back_btn: Button = $Panel/VBox/BackBtn

var current_ship: ShipData = null

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
		var name_lbl = Label.new()
		name_lbl.text = ship.display_name
		row.add_child(name_lbl)

		var status_lbl = Label.new()
		var is_current = _is_current_ship(ship)
		status_lbl.text = "(当前)" if is_current else "(未使用)"
		status_lbl.add_theme_color_override("font_color",
			Color(1, 1, 0.3) if is_current else Color(0.3, 1, 0.3))
		row.add_child(status_lbl)

		var btn = Button.new()
		if is_current:
			btn.text = "装备配置"
			btn.pressed.connect(_select_ship.bind(ship))
		elif not (ship.is_unlocked or GameState.unlocked_ships.has(int(ship.ship_id))):
			btn.text = "未解锁"
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		else:
			btn.text = "选择"
			btn.pressed.connect(_select_ship.bind(ship))
		row.add_child(btn)
		ship_list.add_child(row)

func _is_current_ship(ship: ShipData) -> bool:
	return GameState.selected_ship_id == ship.ship_id

func _select_ship(ship: ShipData) -> void:
	if not (ship.is_unlocked or GameState.unlocked_ships.has(int(ship.ship_id))):
		return
	current_ship = ship
	GameState.selected_ship_id = ship.ship_id
	var equipped_list = GameState.equipped_weapons.get(int(current_ship.ship_id))
	var weapon_name = "空"
	if equipped_list is Array and not equipped_list.is_empty():
		var first_weapon = equipped_list[0]
		if first_weapon is Dictionary:
			weapon_name = first_weapon.get("name", "?")
	elif equipped_list is Dictionary and not equipped_list.is_empty():
		weapon_name = equipped_list.get("name", "?")
	var armor_list: Array = GameState.equipped_armor.get(int(current_ship.ship_id), [])
	if not (armor_list is Array):
		armor_list = []
	var armor_name: String
	if not armor_list.is_empty():
		var first = armor_list[0]
		if first is Dictionary:
			armor_name = first.get("name", "防御装")
			if armor_list.size() > 1:
				armor_name = "%s 等+%d" % [armor_name, armor_list.size() - 1]
		else:
			armor_name = "空"
	else:
		armor_name = "空"
	equip_detail.text = "%s\n武器槽: %s\n护甲槽: %s\n(装备配置下版本实现)" % [
		ship.display_name, weapon_name, armor_name]
	_build_ship_list()

func _on_back() -> void:
	get_parent().close_all_panels()
