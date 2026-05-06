class_name SpawnManager
extends Node

## Manages enemy and boss spawning, EXP orb spawning.

var game_manager: Node2D
var player_stats: PlayerStats

const ENEMY_MELEE_PATH = "res://scenes/EnemyMelee.tscn"
const ENEMY_SENTRY_PATH = "res://scenes/EnemySentry.tscn"
const ENEMY_RAVEN_PATH = "res://scenes/EnemyRaven.tscn"
const BOSS_SCENE_PATH = "res://scenes/BossVoid.tscn"

const _SCENE_MELEE: PackedScene = preload("res://scenes/EnemyMelee.tscn")
const _SCENE_SENTRY: PackedScene = preload("res://scenes/EnemySentry.tscn")
const _SCENE_RAVEN: PackedScene = preload("res://scenes/EnemyRaven.tscn")
const _SCENE_BOSS: PackedScene = preload("res://scenes/BossVoid.tscn")
const _SCENE_EXP_ORB: PackedScene = preload("res://scenes/ExpOrb.tscn")

const _ENEMY_SCENE_MAP: Dictionary = {
	ENEMY_MELEE_PATH: _SCENE_MELEE,
	ENEMY_SENTRY_PATH: _SCENE_SENTRY,
	ENEMY_RAVEN_PATH: _SCENE_RAVEN,
}

const StageData = preload("res://resources/stage_data.gd")

var enemy_root: Node2D
var exp_orb_root: Node2D
var boss_warning: Node

var spawn_timer: float = 0.0

var boss_active: bool = false
var boss_remaining: int = 0
var is_boss_phase: bool = false
var kill_since_boss: int = 0

signal enemy_dead(enemy: Node2D, enemy_type: String)
signal boss_killed(boss: Node2D)

func _init(gm: Node2D, ps: PlayerStats) -> void:
	game_manager = gm
	player_stats = ps

func setup_references(er: Node2D, eor: Node2D, bw: Node) -> void:
	enemy_root = er
	exp_orb_root = eor
	boss_warning = bw

func setup_stage(chapter_id: int, stage_id: int, player_level: int) -> void:
	var stage = StageData.get_stage(chapter_id, stage_id)
	if stage == null:
		stage = StageData.get_stage(1, 1)
	boss_remaining = stage.boss_count
	is_boss_phase = stage.type == StageData.StageType.BOSS_ONLY

	boss_active = false
	kill_since_boss = 0
	spawn_timer = 0.0

	if boss_warning and boss_warning.has_method("hide_warning"):
		boss_warning.hide_warning()

func update_spawning(delta: float, current_stage: StageData.StageInfo, current_chapter_id: int, player_level: int) -> void:
	if game_manager.is_game_over or game_manager.is_paused or game_manager.is_upgrading:
		return

	if boss_active:
		if randf() < 0.5:
			return
	if is_boss_phase:
		return

	var stats_chapter: int = current_chapter_id if current_chapter_id != 6 else 1
	var level_bonus := 1.0 + 0.3 * (player_level - 1)
	var final_density := current_stage.density_mult * level_bonus
	var interval := (2.0 / final_density)

	spawn_timer += delta
	if spawn_timer >= interval:
		spawn_timer = 0.0
		_spawn_enemy(current_stage, current_chapter_id, player_level)

	_check_boss_warning(current_chapter_id, player_level)

func _spawn_enemy(current_stage: StageData.StageInfo, current_chapter_id: int, player_level: int) -> void:
	if not game_manager.player or not is_instance_valid(game_manager.player):
		return

	var enemy_path := _choose_enemy_type()
	if enemy_path == "":
		return

	if not _ENEMY_SCENE_MAP.has(enemy_path):
		push_error("[SpawnManager] Enemy scene not in preload map: " + enemy_path)
		return

	var is_chapter6 := current_chapter_id == 6
	var level_bonus := 1.0 + 0.3 * (player_level - 1)
	var final_strength: float = current_stage.strength_mult * level_bonus
	var spawn_distance := randf_range(600.0, 900.0)
	var spawn_angle := randf_range(0, TAU)

	var enemy_scene: PackedScene = _ENEMY_SCENE_MAP[enemy_path]
	var enemy = enemy_scene.instantiate()
	enemy_root.add_child(enemy)
	enemy.global_position = game_manager.player.global_position + Vector2.from_angle(spawn_angle) * spawn_distance

	var is_elite_spawn: bool = randf() < 0.15
	var tonnage_chapter: int = StageData.get_random_tonnage_chapter() if is_chapter6 else current_chapter_id

	match enemy_path:
		ENEMY_MELEE_PATH:
			var stats := StageData.get_chapter_stats(tonnage_chapter, "melee")
			enemy.setup_enemy(game_manager, stats.hp * final_strength, stats.damage * final_strength,
				stats.speed * (1.0 + (final_strength - 1.0) * 0.2), 0.0, 0.0, 0, "", "", tonnage_chapter, is_elite_spawn)
			enemy.enemy_dead.connect(_on_enemy_dead)
		ENEMY_SENTRY_PATH:
			var stats := StageData.get_chapter_stats(tonnage_chapter, "sentry")
			enemy.setup_enemy(game_manager, stats.hp * final_strength, stats.damage * final_strength,
				stats.speed * (1.0 + (final_strength - 1.0) * 0.2), 0.0, 0.0, 0, "", "", tonnage_chapter, is_elite_spawn)
			enemy.enemy_dead.connect(_on_enemy_dead)
		ENEMY_RAVEN_PATH:
			var stats := StageData.get_chapter_stats(tonnage_chapter, "raven")
			enemy.setup_enemy(game_manager, stats.hp * final_strength, stats.damage * final_strength,
				stats.speed * (1.0 + (final_strength - 1.0) * 0.2), 0.0, 0.0, 0, "", "", tonnage_chapter, is_elite_spawn)
			enemy.enemy_dead.connect(_on_enemy_dead)

	if enemy.has_method("_apply_chapter_icon"):
		enemy._apply_chapter_icon()

func _choose_enemy_type() -> String:
	var rng = randf()
	if kill_since_boss < 20:
		if rng < 0.8:
			return ENEMY_MELEE_PATH
		else:
			return ENEMY_SENTRY_PATH
	elif kill_since_boss < 50:
		if rng < 0.60:
			return ENEMY_MELEE_PATH
		elif rng < 0.85:
			return ENEMY_SENTRY_PATH
		else:
			return ENEMY_RAVEN_PATH
	else:
		if rng < 0.50:
			return ENEMY_MELEE_PATH
		elif rng < 0.80:
			return ENEMY_SENTRY_PATH
		else:
			return ENEMY_RAVEN_PATH

func _check_boss_warning(current_chapter_id: int, player_level: int) -> void:
	if boss_active:
		return
	if is_boss_phase:
		if boss_remaining > 0:
			_spawn_boss(current_chapter_id, player_level)
		return
	if kill_since_boss >= 45 and kill_since_boss < 50:
		if boss_warning and boss_warning.has_method("show_warning"):
			boss_warning.show_warning()
	elif kill_since_boss >= 50:
		_spawn_boss(current_chapter_id, player_level)

func _spawn_boss(current_chapter_id: int, player_level: int) -> void:
	if boss_active:
		return
	SoundManager.play_sfx("boss_appear")
	SoundManager.play_music("battle_boss")
	if not game_manager.player or not is_instance_valid(game_manager.player):
		return

	boss_active = true
	kill_since_boss = 0

	if boss_warning and boss_warning.has_method("hide_warning"):
		boss_warning.hide_warning()

	var game_scene = game_manager.get_parent()
	if game_scene and game_scene.has_method("trigger_screen_shake"):
		game_scene.trigger_screen_shake(15.0, 0.3)
		var overlay = ColorRect.new()
		overlay.color = Color(1.0, 1.0, 1.0, 0.5)
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		game_scene.add_child(overlay)
		var t = game_scene.create_tween()
		t.tween_property(overlay, "modulate:a", 0.0, 0.3)
		t.tween_callback(overlay.queue_free)

	var boss = _SCENE_BOSS.instantiate()
	enemy_root.add_child(boss)

	var spawn_dist = 500.0
	var spawn_angle = randf_range(0, TAU)
	boss.global_position = game_manager.player.global_position + Vector2.from_angle(spawn_angle) * spawn_dist

	var is_chapter6 := current_chapter_id == 6
	var boss_tonnage_chapter: int = StageData.get_random_tonnage_chapter() if is_chapter6 else current_chapter_id
	var boss_stats := StageData.get_chapter_stats(boss_tonnage_chapter, "boss")
	var level_bonus := 1.0 + 0.3 * (player_level - 1)
	var current_stage = game_manager.current_stage
	var final_strength: float = current_stage.strength_mult * level_bonus

	boss.setup_boss(game_manager,
		boss_stats.hp * final_strength,
		boss_stats.damage * final_strength,
		boss_stats.speed * (1.0 + (final_strength - 1.0) * 0.2),
		boss_stats.shield * final_strength,
		boss_tonnage_chapter)
	boss.enemy_dead.connect(_on_enemy_dead)

func spawn_exp_orb(pos: Vector2) -> void:
	var orb = _SCENE_EXP_ORB.instantiate()
	orb.set_game_manager(game_manager)
	orb.global_position = pos
	exp_orb_root.call_deferred("add_child", orb)

func on_boss_killed(boss_node: Node2D) -> void:
	SoundManager.play_music("battle")
	boss_active = false
	kill_since_boss = 0

	if boss_warning and boss_warning.has_method("hide_warning"):
		boss_warning.hide_warning()

	if is_boss_phase:
		boss_remaining -= 1
	boss_killed.emit(boss_node)

func on_enemy_killed() -> void:
	kill_since_boss += 1

func reset() -> void:
	boss_active = false
	kill_since_boss = 0
	spawn_timer = 0.0
	if boss_warning and boss_warning.has_method("hide_warning"):
		boss_warning.hide_warning()

func _on_enemy_dead(enemy: Node2D, enemy_type: String) -> void:
	enemy_dead.emit(enemy, enemy_type)
