extends Control

@onready var ship_list_vbox: VBoxContainer = $Panel/VBox/ShipList/VBox
@onready var cancel_btn: Button = $Panel/VBox/BtnRow/CancelBtn

func _ready() -> void:
	cancel_btn.pressed.connect(_on_cancel)
	_build_ship_list()

func _build_ship_list() -> void:
	for child in ship_list_vbox.get_children():
		child.queue_free()

	var ships = ShipData.get_all_ships()
	var unlocked_count = 0
	for ship in ships:
		var is_unlocked = ship.is_unlocked or GameState.unlocked_ships.has(int(ship.ship_id))
		if not is_unlocked:
			continue
		unlocked_count += 1

		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 60)

		var name_lbl = Label.new()
		name_lbl.text = ship.display_name
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var slots_lbl = Label.new()
		slots_lbl.text = "武x%d 防x%d" % [ship.weapon_slot_count, ship.armor_slot_count]
		slots_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
		row.add_child(slots_lbl)

		var btn = Button.new()
		var is_current = GameState.selected_ship_id == ship.ship_id
		if is_current:
			btn.text = "[当前]"
			btn.disabled = true
		else:
			btn.text = "出发"
			btn.pressed.connect(_on_ship_selected.bind(ship))
		row.add_child(btn)
		ship_list_vbox.add_child(row)

	if unlocked_count <= 1:
		var auto_lbl = Label.new()
		auto_lbl.text = "(仅有1艘可用舰船，直接出发)"
		auto_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		auto_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ship_list_vbox.add_child(auto_lbl)

		for ship in ships:
			var is_unlocked = ship.is_unlocked or GameState.unlocked_ships.has(int(ship.ship_id))
			if is_unlocked:
				_on_ship_selected(ship)
				break

func _on_ship_selected(ship: ShipData) -> void:
	GameState.selected_ship_id = ship.ship_id
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")

func _on_cancel() -> void:
	get_tree().change_scene_to_file("res://scenes/BaseScene.tscn")
