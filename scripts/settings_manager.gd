extends Node

const CONFIG_PATH := "user://settings.cfg"
const SECTION := "audio"

var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0
var master_muted: bool = false
var sfx_muted: bool = false
var music_muted: bool = false

func _ready() -> void:
	_load_settings()

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(CONFIG_PATH)
	if err == OK:
		master_volume = cfg.get_value(SECTION, "master_volume", 1.0)
		sfx_volume = cfg.get_value(SECTION, "sfx_volume", 1.0)
		music_volume = cfg.get_value(SECTION, "music_volume", 1.0)
		master_muted = cfg.get_value(SECTION, "master_muted", false)
		sfx_muted = cfg.get_value(SECTION, "sfx_muted", false)
		music_muted = cfg.get_value(SECTION, "music_muted", false)
		_apply_to_sound_manager()
		return
	master_volume = 1.0
	sfx_volume = 1.0
	music_volume = 1.0
	master_muted = false
	sfx_muted = false
	music_muted = false

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "master_volume", master_volume)
	cfg.set_value(SECTION, "sfx_volume", sfx_volume)
	cfg.set_value(SECTION, "music_volume", music_volume)
	cfg.set_value(SECTION, "master_muted", master_muted)
	cfg.set_value(SECTION, "sfx_muted", sfx_muted)
	cfg.set_value(SECTION, "music_muted", music_muted)
	var err := cfg.save(CONFIG_PATH)
	if err != OK:
		push_error("[SettingsManager] Failed to save settings: " + str(err))

func _apply_to_sound_manager() -> void:
	if has_node("/root/SoundManager"):
		SoundManager.apply_audio_settings(master_volume, sfx_volume, music_volume, master_muted, sfx_muted, music_muted)

func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	_apply_to_sound_manager()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_apply_to_sound_manager()

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_apply_to_sound_manager()

func set_master_muted(m: bool) -> void:
	master_muted = m
	_apply_to_sound_manager()

func set_sfx_muted(m: bool) -> void:
	sfx_muted = m
	_apply_to_sound_manager()

func set_music_muted(m: bool) -> void:
	music_muted = m
	_apply_to_sound_manager()
