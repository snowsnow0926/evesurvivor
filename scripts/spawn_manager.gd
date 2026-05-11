class_name SpawnManager
extends Node

## Manages enemy and boss spawning, EXP orb spawning.

var game_manager: Node2D
var player_stats: PlayerStats
var difficulty_scaler: Node

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

var _balance_config: Dictionary = {}

var enemy_root: Node2D
var exp_orb_root: Node2D
var boss_warning: Node

var spawn_timer: float = 0.0
var spawn_interval: float = 2.0

var boss_active: bool = false
var boss_remaining: int = 0
var is_boss_phase: bool = false
var kill_since_boss: int = 0

var _debug_frame_count: int = 0

## BOSS 关波次控制（适用于所有章节的第6关）
var _boss_wave: int = 0       # 当前波次（0=未开始, 1=第1波, 2=第2波, 3=第3波, 4=全部完成）
var _bosses_alive: int = 0     # 当前波次存活的BOSS数量
var _waiting_next_wave: bool = false  # 是否在等待下一波刷新（锁，防止重复触发）

signal enemy_dead(enemy: Node2D, enemy_type: String)
signal boss_killed(boss: Node2D)

func _init(gm: Node2D, ps: PlayerStats) -> void:
	game_manager = gm
	player_stats = ps
	_load_balance_config()

func _load_balance_config() -> void:
	var path := "res://resources/game_balance.json"
	if ResourceLoader.exists(path):
		var res = ResourceLoader.load(path)
		if res is Dictionary:
			_balance_config = res
		else:
			var f = FileAccess.open(path, FileAccess.READ)
			if f:
				var json_str = f.get_as_text()
				f.close()
				var json = JSON.new()
				if json.parse(json_str) == OK:
					_balance_config = json.data if json.data is Dictionary else {}
	else:
		_balance_config = {}

func _get_balance_value(section: String, key: String, default: int) -> int:
	var sec = _balance_config.get(section, {})
	if sec is Dictionary:
		var val = sec.get(key)
		if val is int or val is float:
			return int(val)
	return default

func _is_safe_to_continue() -> bool:
	if not is_instance_valid(game_manager):
		return false
	if game_manager.is_game_over:
		return false
	return true

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
	spawn_interval = 2.0 / stage.density_mult

	# BOSS 关波次重置
	_boss_wave = 0
	_bosses_alive = 0

	if boss_warning and boss_warning.has_method("hide_warning"):
		boss_warning.hide_warning()

	print_debug("[SpawnManager] setup_stage: chapter=%d stage=%d is_boss_phase=%s boss_count=%d" % [chapter_id, stage_id, is_boss_phase, boss_remaining])

func update_spawn_interval(interval: float) -> void:
	spawn_interval = interval

func update_spawning(delta: float, current_stage: StageData.StageInfo, current_chapter_id: int, player_level: int) -> void:
	_debug_frame_count += 1
	if game_manager.is_game_over or game_manager.is_paused or game_manager.is_upgrading:
		return

	spawn_timer += delta

	# 所有章节的 stage 6（Boss关）不刷新普通怪物，只通过波次逻辑刷 BOSS
	if boss_active and current_stage.id == 6:
		if randf() < 0.5:
			return
	if current_stage.id != 6 and spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		print_debug("[SpawnManager] -> calling _spawn_enemy: stage=%d interval=%.2f" % [current_stage.id, spawn_interval])
		_spawn_enemy(current_stage, current_chapter_id)

	_check_boss_warning(current_stage, current_chapter_id)

	# 调试打印（仅在BOSS相关状态时输出）
	if is_boss_phase or current_stage.id == 6 or _boss_wave > 0:
		print_debug("[SpawnManager] frame=%d: boss_active=%s is_boss_phase=%s stage.id=%d _boss_wave=%d boss_remaining=%d" % [_debug_frame_count, boss_active, is_boss_phase, current_stage.id, _boss_wave, boss_remaining])

func _spawn_enemy(current_stage: StageData.StageInfo, current_chapter_id: int) -> void:
	if not game_manager.player or not is_instance_valid(game_manager.player):
		return

	var enemy_path := _choose_enemy_type()
	if enemy_path == "":
		return

	if not _ENEMY_SCENE_MAP.has(enemy_path):
		push_error("[SpawnManager] Enemy scene not in preload map: " + enemy_path)
		return

	var strength_mult: float = current_stage.strength_mult
	var speed_mult: float = 1.0
	if difficulty_scaler and difficulty_scaler.has_method("get_strength_mult"):
		strength_mult *= difficulty_scaler.get_strength_mult()
		speed_mult = difficulty_scaler.get_speed_mult()

	var spawn_distance := randf_range(600.0, 900.0)
	var spawn_angle := randf_range(0, TAU)

	var enemy_scene: PackedScene = _ENEMY_SCENE_MAP[enemy_path]
	var enemy = enemy_scene.instantiate()
	enemy_root.add_child(enemy)
	enemy.global_position = game_manager.player.global_position + Vector2.from_angle(spawn_angle) * spawn_distance

	var is_elite_spawn: bool = randf() < 0.15
	var tonnage_chapter: int = current_chapter_id

	match enemy_path:
		ENEMY_MELEE_PATH:
			var stats := StageData.get_chapter_stats(tonnage_chapter, "melee")
			enemy.setup_enemy(game_manager, stats.hp * strength_mult, stats.damage * strength_mult,
				stats.speed * speed_mult, 0.0, 0.0, 0, "", "", tonnage_chapter, is_elite_spawn)
			enemy.enemy_dead.connect(_on_enemy_dead)
		ENEMY_SENTRY_PATH:
			var stats := StageData.get_chapter_stats(tonnage_chapter, "sentry")
			enemy.setup_enemy(game_manager, stats.hp * strength_mult, stats.damage * strength_mult,
				stats.speed * speed_mult, 0.0, 0.0, 0, "", "", tonnage_chapter, is_elite_spawn)
			enemy.enemy_dead.connect(_on_enemy_dead)
		ENEMY_RAVEN_PATH:
			var stats := StageData.get_chapter_stats(tonnage_chapter, "raven")
			enemy.setup_enemy(game_manager, stats.hp * strength_mult, stats.damage * strength_mult,
				stats.speed * speed_mult, 0.0, 0.0, 0, "", "", tonnage_chapter, is_elite_spawn)
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
	elif kill_since_boss < _get_balance_value("difficulty", "boss_trigger_kills", 50):
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

func _check_boss_warning(current_stage: StageData.StageInfo, current_chapter_id: int) -> void:
	print_debug("[_check_boss_warning] ENTER: boss_active=%s is_boss_phase=%s stage.id=%d _boss_wave=%d" % [boss_active, is_boss_phase, current_stage.id, _boss_wave])
	if boss_active:
		print_debug("[_check_boss_warning] -> early return: boss_active=true")
		return
	if is_boss_phase and current_stage.id != 6:
		print_debug("[_check_boss_warning] -> normal boss flow (is_boss_phase && stage.id!=6) boss_remaining=%d" % boss_remaining)
		if boss_remaining > 0:
			_spawn_boss(current_chapter_id)
		return

	# BOSS 关（第6关）波次逻辑
	if current_stage.id == 6:
		print_debug("[_check_boss_warning] -> BOSS关 stage6: _waiting_next_wave=%s _boss_wave=%d" % [_waiting_next_wave, _boss_wave])
		if _waiting_next_wave:
			return
		if _boss_wave == 0:
			print_debug("[_check_boss_warning] -> TRIGGER wave 1!")
			_boss_wave = 1
			_spawn_boss_wave(current_stage, current_chapter_id, 1)
		return

	var warn_kills := _get_balance_value("difficulty", "boss_warning_kills", 45)
	var spawn_kills := _get_balance_value("difficulty", "boss_trigger_kills", 50)
	if kill_since_boss >= warn_kills and kill_since_boss < spawn_kills:
		if boss_warning and boss_warning.has_method("show_warning"):
			boss_warning.show_warning()
	elif kill_since_boss >= spawn_kills:
		_spawn_boss(current_chapter_id)

func _spawn_boss_wave(current_stage: StageData.StageInfo, current_chapter_id: int, count: int) -> void:
	print_debug("[_spawn_boss_wave] CALLED: count=%d chapter=%d stage_id=%d" % [count, current_chapter_id, current_stage.id])

	if not is_instance_valid(enemy_root):
		push_error("[SpawnManager] _spawn_boss_wave: enemy_root is invalid")
		return
	if not is_instance_valid(game_manager) or game_manager.is_game_over:
		return

	SoundManager.play_sfx("boss_appear")
	SoundManager.play_music("battle_boss")

	boss_active = true
	_bosses_alive = count

	if boss_warning and boss_warning.has_method("hide_warning"):
		boss_warning.hide_warning()

	var game_scene = game_manager.get_parent()
	if game_scene and game_scene.has_method("trigger_screen_shake"):
		game_scene.call_deferred("trigger_screen_shake", 15.0, 0.3)
		var overlay = ColorRect.new()
		overlay.color = Color(1.0, 1.0, 1.0, 0.5)
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		game_scene.call_deferred("add_child", overlay)
		overlay.call_deferred("add_to_group", "_spawn_boss_overlay")
		overlay.call_deferred("set_process_callback", 1)

	if not game_manager.player or not is_instance_valid(game_manager.player):
		push_error("[SpawnManager] _spawn_boss_wave: player invalid")
		boss_active = false
		return

	var boss_tonnage_chapter: int = current_chapter_id
	var boss_stats := StageData.get_chapter_stats(boss_tonnage_chapter, "boss")
	var strength_mult: float = current_stage.strength_mult
	var speed_mult: float = 1.0
	if difficulty_scaler and difficulty_scaler.has_method("get_strength_mult"):
		strength_mult *= difficulty_scaler.get_strength_mult()
		speed_mult = difficulty_scaler.get_speed_mult()

	for i in range(count):
		if game_manager.is_game_over:
			return
		var delay: float = i * 0.8
		if delay > 0.0:
			await get_tree().create_timer(delay).timeout
			if game_manager.is_game_over:
				return
		var spawn_angle := randf_range(0, TAU)
		var spawn_dist := randf_range(400.0, 700.0)
		var offset_pos: Vector2 = game_manager.player.global_position + Vector2.from_angle(spawn_angle) * spawn_dist

		var boss = _SCENE_BOSS.instantiate()
		enemy_root.add_child(boss)
		boss.global_position = offset_pos
		boss.setup_boss(game_manager,
			boss_stats.hp * strength_mult,
			boss_stats.damage * strength_mult,
			boss_stats.speed * speed_mult,
			boss_stats.shield * strength_mult,
			boss_tonnage_chapter)
		boss.enemy_dead.connect(_on_enemy_dead)
		print_debug("[_spawn_boss_wave] Spawned boss %d/%d at %s" % [i + 1, count, offset_pos])

func _spawn_boss(current_chapter_id: int) -> void:
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

	var boss_tonnage_chapter: int = current_chapter_id
	var boss_stats := StageData.get_chapter_stats(boss_tonnage_chapter, "boss")
	var strength_mult: float = game_manager.current_stage.strength_mult
	var speed_mult: float = 1.0
	if difficulty_scaler and difficulty_scaler.has_method("get_strength_mult"):
		strength_mult *= difficulty_scaler.get_strength_mult()
		speed_mult = difficulty_scaler.get_speed_mult()

	boss.setup_boss(game_manager,
		boss_stats.hp * strength_mult,
		boss_stats.damage * strength_mult,
		boss_stats.speed * speed_mult,
		boss_stats.shield * strength_mult,
		boss_tonnage_chapter)
	boss.enemy_dead.connect(_on_enemy_dead)

func spawn_exp_orb(pos: Vector2) -> void:
	var orb = _SCENE_EXP_ORB.instantiate()
	orb.set_game_manager(game_manager)
	# 经验球生成在敌人残骸附近20px范围内的随机位置，避免与残骸重叠
	var offset := Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
	orb.global_position = pos + offset
	exp_orb_root.call_deferred("add_child", orb)

func on_boss_killed(boss_node: Node2D) -> void:
	SoundManager.play_music("battle")

	if boss_warning and boss_warning.has_method("hide_warning"):
		boss_warning.hide_warning()

	kill_since_boss = 0

	# BOSS 关波次处理
	if _boss_wave > 0:
		_bosses_alive -= 1

		if _bosses_alive <= 0:
			match _boss_wave:
				1:  # 第1波击杀 → 刷新第2波（2个）
					_boss_wave = 2
					boss_active = false
					_waiting_next_wave = true
					var t1 := get_tree()
					if not t1:
						return
					await t1.create_timer(1.5).timeout
					if not _is_safe_to_continue():
						return
					_waiting_next_wave = false
					_spawn_boss_wave(game_manager.current_stage, game_manager.current_chapter_id, 2)
					return  # 中间波次不 emit boss_killed，避免触发游戏结束/loot
				2:  # 第2波击杀 → 刷新第3波（3个）
					_boss_wave = 3
					boss_active = false
					_waiting_next_wave = true
					var t2 := get_tree()
					if not t2:
						return
					await t2.create_timer(1.5).timeout
					if not _is_safe_to_continue():
						return
					_waiting_next_wave = false
					_spawn_boss_wave(game_manager.current_stage, game_manager.current_chapter_id, 3)
					return  # 中间波次不 emit boss_killed
				3:  # 第3波击杀 → 全部通关！
					_boss_wave = 4
					boss_active = false
					boss_remaining = 0  # 触发 game_manager 的过关检测
					# 继续执行到下面的 boss_killed.emit()
				_:
					boss_active = false
					boss_killed.emit(boss_node)
					return
	else:
		boss_active = false
		if is_boss_phase:
			boss_remaining -= 1

	boss_killed.emit(boss_node)

func on_enemy_killed() -> void:
	kill_since_boss += 1

func reset() -> void:
	boss_active = false
	kill_since_boss = 0
	spawn_timer = 0.0
	_boss_wave = 0
	_bosses_alive = 0
	_waiting_next_wave = false
	_debug_frame_count = 0
	if boss_warning and boss_warning.has_method("hide_warning"):
		boss_warning.hide_warning()

func _on_enemy_dead(enemy: Node2D, enemy_type: String) -> void:
	enemy_dead.emit(enemy, enemy_type)
