extends Control

@onready var inventory_grid: GridContainer = $Panel/VBox/InventoryGrid
@onready var crafting_slots: HBoxContainer = $Panel/VBox/CraftingSlots
@onready var result_preview: Label = $Panel/VBox/ResultPreview
@onready var craft_btn: Button = $Panel/VBox/CraftBtn
@onready var back_btn: Button = $Panel/VBox/BackBtn

var selected_items: Array = [null, null]

const CRAFTING_COSTS: Dictionary = {
	EquipmentData.Quality.COMMON: 200,
	EquipmentData.Quality.UNCOMMON: 500,
	EquipmentData.Quality.RARE: 1500,
	EquipmentData.Quality.LEGENDARY: 5000,
	EquipmentData.Quality.EPIC: 20000,
}

func _ready() -> void:
	if craft_btn:
		craft_btn.pressed.connect(_on_craft_pressed)
	if back_btn:
		back_btn.pressed.connect(_on_back)
	_build_inventory()

func _build_inventory() -> void:
	for child in inventory_grid.get_children():
		child.queue_free()

	for item in GameState.equipment_inventory:
		var btn = _make_item_button(item)
		inventory_grid.add_child(btn)

func _make_item_button(item: Dictionary) -> Button:
	var btn = Button.new()
	btn.text = item.get("name", "?")
	var q = item.get("quality", 0)
	btn.add_theme_color_override("font_color", EquipmentData.get_quality_color(q))
	btn.custom_minimum_size = Vector2(80, 80)
	btn.pressed.connect(_on_item_selected.bind(item))
	return btn

func _on_item_selected(item: Dictionary) -> void:
	for i in range(2):
		if selected_items[i] == null:
			selected_items[i] = item
			_update_crafting_slots()
			break
	_update_preview()

func _update_crafting_slots() -> void:
	for i in range(2):
		var slot = crafting_slots.get_child(i)
		if selected_items[i]:
			slot.get_node("Label").text = selected_items[i].get("name", "?")
		else:
			slot.get_node("Label").text = "[空]"
	_update_preview()

func _update_preview() -> void:
	if selected_items[0] == null or selected_items[1] == null:
		result_preview.text = "放入2件相同品质装备进行合成"
		if craft_btn:
			craft_btn.disabled = true
		return

	if selected_items[0].get("quality") != selected_items[1].get("quality"):
		result_preview.text = "品质不匹配！"
		if craft_btn:
			craft_btn.disabled = true
		return

	var q = selected_items[0].get("quality")
	var next_q = q + 1
	if next_q > EquipmentData.Quality.MYTHIC:
		result_preview.text = "已是最高品质！"
		if craft_btn:
			craft_btn.disabled = true
		return

	var cost = CRAFTING_COSTS.get(q, 0)
	result_preview.text = "合成 %s\n消耗 %d 星币\n当前 %d 星币" % [
		EquipmentData.get_quality_name(next_q), cost, GameState.star_coin]
	if craft_btn:
		craft_btn.disabled = GameState.star_coin < cost

func _on_craft_pressed() -> void:
	if selected_items[0] == null or selected_items[1] == null:
		return
	if selected_items[0].get("quality") != selected_items[1].get("quality"):
		return

	var q = selected_items[0].get("quality")
	var next_q = q + 1
	var cost = CRAFTING_COSTS.get(q, 0)

	if GameState.star_coin < cost:
		return

	GameState.star_coin -= cost
	GameState.equipment_inventory.erase(selected_items[0])
	GameState.equipment_inventory.erase(selected_items[1])

	var new_item = {
		"equip_id": str(randi()),
		"equip_type": selected_items[0].get("equip_type", 0),
		"quality": next_q,
		"name": EquipmentData.get_quality_name(next_q) + " " +
				("武器" if selected_items[0].get("equip_type") == 0 else "护甲"),
	}
	GameState.equipment_inventory.append(new_item)

	selected_items = [null, null]
	_build_inventory()
	_update_crafting_slots()

func _on_back() -> void:
	get_parent().close_all_panels()
