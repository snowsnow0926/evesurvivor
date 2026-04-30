extends Control

signal pause_toggled
signal retreat_requested
signal self_destruct_requested

@onready var panel: Panel = $Panel
@onready var continue_btn: Button = $Panel/VBox/ContinueBtn
@onready var retreat_btn: Button = $Panel/VBox/RetreatBtn
@onready var self_destruct_btn: Button = $Panel/VBox/SelfDestructBtn

var game_manager: Node2D
var is_open: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	is_open = false
	_connect_buttons()
	print("[PauseMenu] ready, process_mode=", process_mode)

func _connect_buttons() -> void:
	if continue_btn:
		continue_btn.pressed.connect(_on_continue_pressed)
	if retreat_btn:
		retreat_btn.pressed.connect(_on_retreat_pressed)
	if self_destruct_btn:
		self_destruct_btn.pressed.connect(_on_self_destruct_pressed)

func open_menu(gm: Node2D) -> void:
	game_manager = gm
	visible = true
	is_open = true
	print("[PauseMenu] opened, visible=", visible, " process_mode=", process_mode)
	if game_manager:
		game_manager.is_paused = true
		get_tree().paused = true

func _on_continue_pressed() -> void:
	SoundManager.play_sfx("button_click")
	print("[PauseMenu] continue pressed")
	close_menu()

func close_menu() -> void:
	visible = false
	is_open = false
	if game_manager and is_instance_valid(game_manager):
		game_manager.is_paused = false
	get_tree().paused = false

func _on_retreat_pressed() -> void:
	print("[PauseMenu] retreat pressed, is_game_over=", game_manager.is_game_over if game_manager else "no gm")
	if game_manager and is_instance_valid(game_manager):
		game_manager.on_retreat()
	# don't close menu here — game_ended signal will trigger settlement screen

func _on_self_destruct_pressed() -> void:
	print("[PauseMenu] self_destruct pressed")
	if game_manager and is_instance_valid(game_manager):
		game_manager.on_self_destruct()
	# don't close menu here — game_ended signal will trigger transition
