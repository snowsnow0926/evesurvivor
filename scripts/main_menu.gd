extends Control

@onready var start_btn: Button = $Panel/VBox/StartBtn
@onready var load_game_btn: Button = $Panel/VBox/LoadGameBtn
@onready var quit_btn: Button = $Panel/VBox/QuitBtn
@onready var save_ui: Control = $SaveUI
@onready var star_container: Node2D = $BG/StarContainer
@onready var bg: TextureRect = $BG
@onready var video_player: VideoStreamPlayer = %VideoPlayer

var _star_sprites: Array[Sprite2D] = []
var _time: float = 0.0
var _fade_tween: Tween = null
var _is_playing_video: bool = false

func _ready() -> void:
	SoundManager.play_music("menu")
	_generate_stars()
	_fade_in()
	_setup_bg()

	var buttons := [start_btn, load_game_btn, quit_btn]
	for btn in buttons:
		if btn:
			btn.pressed.connect(_on_start_pressed if btn == start_btn
					else _on_load_game_pressed if btn == load_game_btn
					else _on_quit_pressed)

	save_ui.save_loaded.connect(_on_save_loaded)
	save_ui.new_game_requested.connect(_on_new_game_requested)
	save_ui.save_completed.connect(_on_save_completed)

	video_player.finished.connect(_on_video_finished)

func _setup_bg() -> void:
	bg.texture = load("res://assets/base/menu/menu_bg.png")

func _generate_stars() -> void:
	var rng := RandomNumberGenerator.new()
	var viewport_size := get_viewport_rect().size

	for i in 80:
		var star := Sprite2D.new()
		var size: float = rng.randf_range(1.0, 3.0)
		star.texture = _make_star_texture(size)
		star.position = Vector2(rng.randf_range(0, viewport_size.x), rng.randf_range(0, viewport_size.y))
		var brightness: float = rng.randf_range(0.4, 1.0)
		var hue: float = rng.randf_range(-0.05, 0.1)
		star.modulate = Color.from_hsv(hue, 0.2, brightness, brightness)
		star.z_index = -1
		star_container.add_child(star)
		_star_sprites.append(star)

	for i in 20:
		var sparkle := Sprite2D.new()
		var size: float = rng.randf_range(2.0, 4.0)
		sparkle.texture = _make_sparkle_texture(size)
		sparkle.position = Vector2(rng.randf_range(0, viewport_size.x), rng.randf_range(0, viewport_size.y))
		sparkle.modulate = Color(0.7, 0.85, 1.0, rng.randf_range(0.3, 0.7))
		sparkle.z_index = -1
		star_container.add_child(sparkle)
		_star_sprites.append(sparkle)

func _make_star_texture(radius: float) -> ImageTexture:
	var size := int(radius * 2.0 + 2.0)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2i(size / 2, size / 2)
	for y in range(size):
		for x in range(size):
			var dist := Vector2i(x, y).distance_to(center)
			if dist <= radius:
				var alpha: float = 1.0 - (dist / radius) * 0.5
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	var tex := ImageTexture.create_from_image(image)
	return tex

func _make_sparkle_texture(size: float) -> ImageTexture:
	var s := int(size * 2.0 + 4.0)
	var image := Image.create(s, s, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var c := Vector2i(s / 2, s / 2)
	var cross_len := int(size)
	for i in range(-cross_len, cross_len + 1):
		var alpha: float = 1.0 - abs(i) / float(cross_len) * 0.5
		image.set_pixel(c.x + i, c.y, Color(1, 1, 1, alpha))
		image.set_pixel(c.x, c.y + i, Color(1, 1, 1, alpha))
	var tex := ImageTexture.create_from_image(image)
	return tex

func _process(delta: float) -> void:
	_time += delta
	for star in _star_sprites:
		var flicker: float = 0.75 + sin(_time * 1.5 + star.position.x * 0.01 + star.position.y * 0.007) * 0.25
		var base_alpha := star.modulate.a
		star.modulate.a = flicker * base_alpha

func _fade_in() -> void:
	modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_OUT)
	_fade_tween.play()

func _on_start_pressed() -> void:
	SoundManager.play_sfx("button_click")
	_is_playing_video = true
	_play_intro_video()

func _on_load_game_pressed() -> void:
	SoundManager.play_sfx("button_click")
	save_ui.visible = true

func _on_save_loaded(_slot_idx: int) -> void:
	save_ui.visible = false

func _on_save_completed(_slot_idx: int) -> void:
	save_ui.visible = false

func _on_new_game_requested() -> void:
	save_ui.visible = false
	_is_playing_video = true
	_play_intro_video()

func _on_quit_pressed() -> void:
	SoundManager.play_sfx("button_click")
	get_tree().quit()

func _play_intro_video() -> void:
	modulate.a = 1.0
	bg.visible = false
	star_container.visible = false
	$Panel.visible = false
	video_player.visible = true
	video_player.play()

func _on_video_finished() -> void:
	GameState.reset_all_data()
	GameState.current_save_slot = GameState.SLOT_AUTO
	GameState.pending_new_game_slot = GameState.SLOT_AUTO
	get_tree().change_scene_to_file("res://scenes/CharacterCreate.tscn")
