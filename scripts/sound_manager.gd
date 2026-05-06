extends Node

const SFX_RESOURCES: Dictionary = {
	"shoot_missile":   "",
	"shoot_cannon":    "",
	"shoot_railgun":   "",
	"shoot_laser":     "",
	"hit":             "",
	"crit":            "",
	"shield_hit":      "",
	"shield_break":    "",
	"player_hurt":     "",
	"enemy_death":     "",
	"upgrade":         "",
	"upgrade_select":  "",
	"player_death":    "",
	"boss_appear":     "",
	"boss_death":      "",
	"button_click":    "",
	"retreat_success": "",
}

var sfx_players: Dictionary = {}
var music_player: AudioStreamPlayer
var sfx_bus: StringName = &"Master"
var music_bus: StringName = &"Master"
var sfx_volume: float = 0.0
var music_volume: float = 0.0
var current_music: String = ""

func _ready() -> void:
	_setup_sfx_players()
	_setup_music_player()

func _setup_sfx_players() -> void:
	for sfx_name in SFX_RESOURCES.keys():
		var player = AudioStreamPlayer.new()
		player.name = "SFX_" + sfx_name
		player.bus = sfx_bus
		player.volume_db = sfx_volume
		add_child(player)
		sfx_players[sfx_name] = player

func _setup_music_player() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = music_bus
	music_player.volume_db = music_volume
	music_player.autoplay = false
	add_child(music_player)

func play_sfx(sfx_name: String, volume_override: float = 0.0) -> void:
	if not sfx_players.has(sfx_name):
		return
	var resource_path = SFX_RESOURCES[sfx_name]
	if resource_path == "":
		return
	if not ResourceLoader.exists(resource_path):
		return
	var player = sfx_players[sfx_name]
	if player.playing:
		player.stop()
	var stream = load(resource_path)
	if stream:
		player.stream = stream
		if volume_override != 0.0:
			player.volume_db = volume_override
		player.play()

func play_music(music_name: String, fade_duration: float = 0.5) -> void:
	if current_music == music_name and music_player.playing:
		return
	var resource_path = _get_music_path(music_name)
	if resource_path == "":
		return
	if not ResourceLoader.exists(resource_path):
		return

	if fade_duration > 0 and music_player.playing:
		_fade_out_music(fade_duration)
		await get_tree().create_timer(fade_duration).timeout

	var stream = load(resource_path)
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

func set_sfx_volume(volume_db: float) -> void:
	sfx_volume = volume_db
	for player in sfx_players.values():
		player.volume_db = volume_db

func set_music_volume(volume_db: float) -> void:
	music_volume = volume_db
	music_player.volume_db = volume_db

func get_sfx_volume() -> float:
	return sfx_volume

func get_music_volume() -> float:
	return music_volume
