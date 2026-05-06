extends Control

@onready var start_btn: Button = $Panel/VBox/StartBtn
@onready var load_game_btn: Button = $Panel/VBox/LoadGameBtn
@onready var quit_btn: Button = $Panel/VBox/QuitBtn
@onready var save_ui: Control = $SaveUI

func _ready() -> void:
	SoundManager.play_music("menu")
	if start_btn:
		start_btn.pressed.connect(_on_start_pressed)
	if load_game_btn:
		load_game_btn.pressed.connect(_on_load_game_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)
	save_ui.save_loaded.connect(_on_save_loaded)
	save_ui.new_game_requested.connect(_on_new_game_requested)
	save_ui.save_completed.connect(_on_save_completed)

func _on_start_pressed() -> void:
	SoundManager.play_sfx("button_click")
	GameState.reset_all_data()
	get_tree().change_scene_to_file("res://scenes/CharacterCreate.tscn")

func _on_load_game_pressed() -> void:
	SoundManager.play_sfx("button_click")
	save_ui.visible = true

func _on_save_loaded(_slot_idx: int) -> void:
	save_ui.visible = false

func _on_save_completed(slot_idx: int) -> void:
	save_ui.visible = false

func _on_new_game_requested() -> void:
	save_ui.visible = false

func _on_quit_pressed() -> void:
	SoundManager.play_sfx("button_click")
	get_tree().quit()
