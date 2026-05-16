extends Control

signal closed

@onready var master_slider: HSlider = $Panel/Margin/VBox/MasterRow/HSlider
@onready var master_mute: CheckButton = $Panel/Margin/VBox/MasterRow/MuteCheck
@onready var sfx_slider: HSlider = $Panel/Margin/VBox/SFXRow/HSlider
@onready var sfx_mute: CheckButton = $Panel/Margin/VBox/SFXRow/MuteCheck
@onready var music_slider: HSlider = $Panel/Margin/VBox/MusicRow/HSlider
@onready var music_mute: CheckButton = $Panel/Margin/VBox/MusicRow/MuteCheck
@onready var close_btn: Button = $Panel/Margin/VBox/CloseBtn

func _ready() -> void:
	_close_on_outside_click()
	_connect_signals()
	_load_current_settings()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		_on_close_pressed()

func _close_on_outside_click() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.name = "BgOverlay"
	bg.color = Color(0, 0, 0, 0.5)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(_on_bg_overlay_input)
	add_child(bg)
	move_child(bg, 0)

func _on_bg_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_on_close_pressed()

func _connect_signals() -> void:
	master_slider.value_changed.connect(_on_master_volume_changed)
	master_mute.toggled.connect(_on_master_mute_toggled)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	sfx_mute.toggled.connect(_on_sfx_mute_toggled)
	music_slider.value_changed.connect(_on_music_volume_changed)
	music_mute.toggled.connect(_on_music_mute_toggled)
	close_btn.pressed.connect(_on_close_pressed)

func _load_current_settings() -> void:
	master_slider.value = SettingsManager.master_volume
	master_mute.set_pressed_no_signal(SettingsManager.master_muted)
	sfx_slider.value = SettingsManager.sfx_volume
	sfx_mute.set_pressed_no_signal(SettingsManager.sfx_muted)
	music_slider.value = SettingsManager.music_volume
	music_mute.set_pressed_no_signal(SettingsManager.music_muted)
	_apply_slider_style()

func _apply_slider_style() -> void:
	for row in [$Panel/Margin/VBox/MasterRow, $Panel/Margin/VBox/SFXRow, $Panel/Margin/VBox/MusicRow]:
		var slider: HSlider = row.get_node("HSlider")
		var fill_style := StyleBoxFlat.new()
		fill_style.bg_color = Color(0.25, 0.55, 0.9, 0.8)
		var grab_area_style := StyleBoxFlat.new()
		grab_area_style.bg_color = Color(0.05, 0.1, 0.2, 0.8)
		slider.add_theme_stylebox_override("fill", fill_style)
		slider.add_theme_stylebox_override("grabber_area", grab_area_style)

func _on_master_volume_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)
	SoundManager.play_sfx("button_click")

func _on_master_mute_toggled(toggled: bool) -> void:
	SettingsManager.set_master_muted(toggled)

func _on_sfx_volume_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)
	SoundManager.play_sfx("button_click")

func _on_sfx_mute_toggled(toggled: bool) -> void:
	SettingsManager.set_sfx_muted(toggled)

func _on_music_volume_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)
	SoundManager.play_sfx("button_click")

func _on_music_mute_toggled(toggled: bool) -> void:
	SettingsManager.set_music_muted(toggled)

func _on_close_pressed() -> void:
	SoundManager.play_sfx("button_click")
	SettingsManager.save_settings()
	emit_signal("closed")
	queue_free()
