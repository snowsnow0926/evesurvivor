extends Control

@onready var start_btn: Button = $Panel/VBox/StartBtn
@onready var load_game_btn: Button = $Panel/VBox/LoadGameBtn
@onready var quit_btn: Button = $Panel/VBox/QuitBtn
@onready var coin_label: Label = $Panel/VBox/CoinLabel
@onready var minerals_label: Label = $Panel/VBox/MineralsLabel
@onready var ship_status: Label = $Panel/VBox/ShipStatus
@onready var repairs_btn: Button = $Panel/VBox/RepairsBtn
@onready var save_ui: Control = $SaveUI

func _ready() -> void:
	SoundManager.play_music("menu")
	_update_display()
	if start_btn:
		start_btn.pressed.connect(_on_start_pressed)
	if load_game_btn:
		load_game_btn.pressed.connect(_on_load_game_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)
	if repairs_btn:
		repairs_btn.pressed.connect(_on_repair_pressed)
	save_ui.save_loaded.connect(_on_save_loaded)
	save_ui.new_game_requested.connect(_on_new_game_requested)

func _update_display() -> void:
	if coin_label:
		coin_label.text = "星币: %d" % GameState.star_coin
	if minerals_label:
		minerals_label.text = "矿物: %d低/%d中/%d高" % [GameState.minerals_low, GameState.minerals_mid, GameState.minerals_high]
	if ship_status:
		if GameState.ship_damaged:
			ship_status.text = "舰船状态: 损坏"
			ship_status.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
		else:
			ship_status.text = "舰船状态: 完好"
			ship_status.add_theme_color_override("font_color", Color(0.3, 1, 0.3, 1))
	if repairs_btn:
		repairs_btn.disabled = not GameState.ship_damaged or GameState.star_coin < GameState.get_repair_cost()

func _on_start_pressed() -> void:
	SoundManager.play_sfx("button_click")
	GameState.reset_for_new_run()
	get_tree().change_scene_to_file("res://scenes/BaseScene.tscn")

func _on_repair_pressed() -> void:
	if GameState.repair_ship():
		_update_display()

func _on_load_game_pressed() -> void:
	SoundManager.play_sfx("button_click")
	save_ui.visible = true

func _on_save_loaded(_slot_idx: int) -> void:
	save_ui.visible = false

func _on_new_game_requested() -> void:
	save_ui.visible = false

func _on_quit_pressed() -> void:
	SoundManager.play_sfx("button_click")
	get_tree().quit()
