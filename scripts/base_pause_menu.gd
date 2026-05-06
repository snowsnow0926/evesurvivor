extends Control

@onready var overlay: ColorRect = $Overlay
@onready var continue_btn: Button = $Panel/VBox/ContinueBtn
@onready var save_game_btn: Button = $Panel/VBox/SaveGameBtn
@onready var load_game_btn: Button = $Panel/VBox/LoadGameBtn
@onready var main_menu_btn: Button = $Panel/VBox/MainMenuBtn
@onready var quit_btn: Button = $Panel/VBox/QuitBtn

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_buttons()

func _connect_buttons() -> void:
	if continue_btn:
		continue_btn.pressed.connect(_on_continue_pressed)
	if save_game_btn:
		save_game_btn.pressed.connect(_on_save_game_pressed)
	if load_game_btn:
		load_game_btn.pressed.connect(_on_load_game_pressed)
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_main_menu_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)

func open_menu() -> void:
	visible = true
	get_tree().paused = true

func close_menu() -> void:
	visible = false
	get_tree().paused = false

func _on_continue_pressed() -> void:
	SoundManager.play_sfx("button_click")
	close_menu()

func _on_save_game_pressed() -> void:
	SoundManager.play_sfx("button_click")
	var scene = get_tree().current_scene
	if scene and scene.has_method("open_save_ui_for_save"):
		scene.open_save_ui_for_save()
		close_menu()

func _on_load_game_pressed() -> void:
	SoundManager.play_sfx("button_click")
	# 打开存档选择界面，让用户选择要读取的存档位
	var scene = get_tree().current_scene
	if scene and scene.has_method("open_save_ui_for_load"):
		scene.open_save_ui_for_load()
	close_menu()

func _on_main_menu_pressed() -> void:
	SoundManager.play_sfx("button_click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_quit_pressed() -> void:
	SoundManager.play_sfx("button_click")
	get_tree().quit()
