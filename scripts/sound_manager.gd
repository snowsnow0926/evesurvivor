extends Node

const SFX_RESOURCES: Dictionary = {
	"shoot_missile":   "res://assets/sfx/shoot_missile.ogg",
	"shoot_cannon":    "res://assets/sfx/shoot_cannon.ogg",
	"shoot_railgun":   "res://assets/sfx/shoot_railgun.ogg",
	"shoot_laser":     "res://assets/sfx/shoot_laser.ogg",
	"hit":             "res://assets/sfx/hit.ogg",
	"crit":            "res://assets/sfx/crit.ogg",
	"shield_hit":      "res://assets/sfx/shield_hit.ogg",
	"shield_break":    "res://assets/sfx/shield_break.ogg",
	"player_hurt":     "res://assets/sfx/player_hurt.ogg",
	"enemy_death":     "res://assets/sfx/enemy_death.ogg",
	"upgrade":         "res://assets/sfx/upgrade.ogg",
	"upgrade_select":  "res://assets/sfx/upgrade_select.ogg",
	"player_death":    "res://assets/sfx/player_death.ogg",
	"boss_appear":     "",
	"boss_death":      "",
	"button_click":    "res://assets/sfx/button_click.ogg",
	"retreat_success": "res://assets/sfx/retreat_success.ogg",
}

var sfx_players: Dictionary = {}
var sfx_streams: Dictionary = {}
var music_streams: Dictionary = {}
var music_player: AudioStreamPlayer

var _sfx_volume: float = 1.0
var _music_volume: float = 1.0
var _sfx_muted: bool = false
var _music_muted: bool = false

var current_music: String = ""

func _preload_music_streams() -> void:
	for music_key in ["menu", "battle", "battle_boss", "base", "settlement", "race_select"]:
		var path = _get_music_path(music_key)
		if path != "" and ResourceLoader.exists(path):
			music_streams[music_key] = load(path)

func _ready() -> void:
	_setup_sfx_players()
	_setup_music_player()
	_preload_streams()
	_preload_music_streams()

func _preload_streams() -> void:
	for sfx_name in SFX_RESOURCES.keys():
		var path = SFX_RESOURCES[sfx_name]
		if path != "" and ResourceLoader.exists(path):
			sfx_streams[sfx_name] = load(path)

func _setup_sfx_players() -> void:
	for sfx_name in SFX_RESOURCES.keys():
		var player := AudioStreamPlayer.new()
		player.name = "SFX_" + sfx_name
		player.bus = &"SFX"
		add_child(player)
		sfx_players[sfx_name] = player

func _setup_music_player() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = &"Music"
	music_player.autoplay = false
	add_child(music_player)

func _linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return linear * 80.0 - 80.0

func apply_audio_settings(master: float, sfx: float, music: float, master_muted: bool, sfx_muted: bool, music_muted: bool) -> void:
	var master_db := _linear_to_db(master) if not master_muted else -80.0
	var sfx_db := 0.0 if not sfx_muted else -80.0
	var music_db := _linear_to_db(music) if not music_muted else -80.0

	_sfx_volume = sfx
	_music_volume = music
	_sfx_muted = sfx_muted
	_music_muted = music_muted

	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Master"), master_db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"SFX"), sfx_db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"), music_db)

func play_sfx(sfx_name: String, volume_override: float = 0.0) -> void:
	if not sfx_players.has(sfx_name):
		return
	var stream = sfx_streams.get(sfx_name) as AudioStream
	if not stream:
		return
	var player = sfx_players[sfx_name]
	if player.playing:
		player.stop()
	player.stream = stream
	var linear_vol: float = volume_override if volume_override > 0.0 else _sfx_volume
	player.volume_db = _linear_to_db(linear_vol)
	player.play()

func play_music(music_name: String, fade_duration: float = 0.5) -> void:
	if current_music == music_name and music_player.playing:
		return
	var resource_path = _get_music_path(music_name)
	if resource_path == "":
		return

	if fade_duration > 0 and music_player.playing:
		_fade_out_music(fade_duration)
		await get_tree().create_timer(fade_duration).timeout

	var stream = music_streams.get(music_name) as AudioStream
	if stream:
		music_player.stream = stream
		music_player.play()
		current_music = music_name

func stop_music(fade_duration: float = 0.5) -> void:
	if fade_duration > 0 and music_player.playing:
		_fade_out_music(fade_duration)
		await get_tree().create_timer(fade_duration).timeout
	music_player.stop()
	current_music = ""

func _fade_out_music(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80.0, duration)

func _get_music_path(music_name: String) -> String:
	match music_name:
		"menu":
			return "res://assets/music/menu.ogg"
		"battle":
			return "res://assets/music/battle.ogg"
		"battle_boss":
			return "res://assets/music/battle_boss.ogg"
		"base":
			return "res://assets/music/base.ogg"
		"settlement":
			return "res://assets/music/settlement.ogg"
		"race_select":
			return "res://assets/music/race_select.ogg"
	return ""

func get_sfx_volume() -> float:
	return _sfx_volume

func get_music_volume() -> float:
	return _music_volume

func is_sfx_muted() -> bool:
	return _sfx_muted

func is_music_muted() -> bool:
	return _music_muted
