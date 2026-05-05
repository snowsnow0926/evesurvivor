extends Control

@onready var overlay: ColorRect = $Overlay
@onready var continue_btn: Button = $Panel/VBox/ContinueBtn
@onready var save_game_btn: Button = $Panel/VBox/SaveGameBtn
@onready var load_game_btn: Button = $Panel/VBox/LoadGameBtn
@onready var main_menu_btn: Button = $Panel/VBox/MainMenuBtn
@onready var quit_btn: Button = $Panel/VBox/QuitBtn

var _slot_dialog: Control = null

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_buttons()
	_init_slot_dialog()

func _init_slot_dialog() -> void:
	var packed = load("res://scenes/SaveSlotDialog.tscn")
	if packed:
		_slot_dialog = packed.instantiate()
		_slot_dialog.visible = false
		add_child(_slot_dialog)
		if _slot_dialog.has_signal("slot_selected"):
			if not _slot_dialog.slot_selected.is_connected(_on_slot_selected):
				_slot_dialog.slot_selected.connect(_on_slot_selected)
		if _slot_dialog.has_signal("cancelled"):
			if not _slot_dialog.cancelled.is_connected(_on_slot_cancelled):
				_slot_dialog.cancelled.connect(_on_slot_cancelled)

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
	if _slot_dialog:
		_slot_dialog.open(true)

func _on_load_game_pressed() -> void:
	SoundManager.play_sfx("button_click")
	if _slot_dialog:
		_slot_dialog.open(false)

func _on_slot_selected(slot_idx: int, is_save: bool) -> void:
	if is_save:
		GameState.current_save_slot = slot_idx
		GameState.save_save_slot(slot_idx)
		var popup = AcceptDialog.new()
		popup.dialog_text = "游戏已保存到存档位 %d" % (slot_idx + 1)
		add_child(popup)
		popup.popup_centered()
	else:
		GameState.current_save_slot = slot_idx
		var ok = GameState.load_save_slot(slot_idx)
		if ok:
			close_menu()
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/BaseScene.tscn")
		else:
			var popup = AcceptDialog.new()
			popup.dialog_text = "该存档位为空"
			add_child(popup)
			popup.popup_centered()

func _on_slot_cancelled() -> void:
	pass

func _on_main_menu_pressed() -> void:
	SoundManager.play_sfx("button_click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_quit_pressed() -> void:
	SoundManager.play_sfx("button_click")
	get_tree().quit()
