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
var boss_encounter_ui: Node

var spawn_timer: float = 0.0
var spawn_interval: float = 2.0

var boss_active: bool = false
var boss_remaining: int = 0
var is_boss_phase: bool = false
var kill_since_boss: int = 0

var _debug_frame_count: int = 0

## 第6关时间波次BOSS控制（所有章节通用）
## 波次计划：第2秒刷1只 → 第30秒刷2只 → 第75秒刷3只
var _s6_wave: int = 0           # 0=未开始 1=第1波 2=第2波 3=第3波 4=全部完成
var _s6_bosses_alive: int = 0   # 当前波次存活数
var _s6_spawned_this_wave: int = 0  # 本波已刷数量
var _s6_wave_counts: Array = [1, 2, 3]  # [第1波数量, 第2波数量, 第3波数量]
var _s6_wave_times: Array = [2.0, 30.0, 75.0]  # [第1波触发秒, 第2波触发秒, 第3波触发秒]
var _s6_next_spawn_frames: int = 0  # 下一只BOSS的帧延迟（用于多只间隔生成）
var _s6_elapsed: float = 0.0  # 第6关独立计时器（不受 is_unlimited_mode 影响）

signal enemy_dead(enemy: Node2D, enemy_type: String)
signal boss_killed(boss: Node2D)
signal s6_all_bosses_defeated()

var _pending_boss_entry: BossEntry
var _pending_chapter_id: int = 1
var _pending_strength_mult: float = 1.0
var _pending_speed_mult: float = 1.0
var _pending_tonnage_chapter: int = 1
var _pending_is_s6: bool = false
var _is_spawning_boss: bool = false
var _spawn_timeout_timer: SceneTreeTimer = null

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

func setup_references(er: Node2D, eor: Node2D, bw: Node, beui: Node = null) -> void:
	enemy_root = er
	exp_orb_root = eor
	boss_warning = bw
	boss_encounter_ui = beui
	print_debug("[SpawnManager] setup_references: boss_encounter_ui=%s has_signal=%s" % [boss_encounter_ui, boss_encounter_ui.has_signal("encounter_finished") if boss_encounter_ui else false])
	if boss_encounter_ui and boss_encounter_ui.has_signal("encounter_finished"):
		if not boss_encounter_ui.encounter_finished.is_connected(_on_encounter_finished):
			boss_encounter_ui.encounter_finished.connect(_on_encounter_finished)
			print_debug("[SpawnManager] encounter_finished connected successfully")

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

	# 第6关时间波次BOSS重置
	_s6_wave = 0
	_s6_bosses_alive = 0
	_s6_spawned_this_wave = 0
	_s6_next_spawn_frames = 0
	_s6_elapsed = 0.0

	if boss_warning and boss_warning.has_method("hide_warning"):
		boss_warning.hide_warning()

	print_debug("[SpawnManager] setup_stage: chapter=%d stage=%d is_boss_phase=%s boss_count=%d" % [chapter_id, stage_id, is_boss_phase, boss_remaining])

func update_spawn_interval(interval: float) -> void:
	spawn_interval = interval

func update_spawning(delta: float, current_stage: StageData.StageInfo, current_chapter_id: int, player_level: int) -> void:
	_debug_frame_count += 1
	if game_manager.is_game_over or game_manager.is_paused or game_manager.is_upgrading:
		return

	# 所有章节的 stage 6（第6关）：时间波次BOSS逻辑
	if current_stage.id == 6:
		_s6_elapsed += delta * game_manager.game_speed
		_update_s6_boss_waves(delta)
		return

	# 非第6关：正常普通怪物刷新
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		print_debug("[SpawnManager] -> calling _spawn_enemy: stage=%d interval=%.2f" % [current_stage.id, spawn_interval])
		_spawn_enemy(current_stage, current_chapter_id)

	_check_boss_warning(current_stage, current_chapter_id)

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
	print_debug("[_check_boss_warning] ENTER: boss_active=%s is_boss_phase=%s stage.id=%d" % [boss_active, is_boss_phase, current_stage.id])
	if boss_active:
		print_debug("[_check_boss_warning] -> early return: boss_active=true")
		return
	if is_boss_phase:
		print_debug("[_check_boss_warning] -> normal boss flow (is_boss_phase) boss_remaining=%d" % boss_remaining)
		if boss_remaining > 0:
			_spawn_boss(current_chapter_id)
		return

	var warn_kills := _get_balance_value("difficulty", "boss_warning_kills", 45)
	var spawn_kills := _get_balance_value("difficulty", "boss_trigger_kills", 50)
	if kill_since_boss >= warn_kills and kill_since_boss < spawn_kills:
		if boss_warning and boss_warning.has_method("show_warning"):
			boss_warning.show_warning()
	elif kill_since_boss >= spawn_kills:
		_spawn_boss(current_chapter_id)

func _update_s6_boss_waves(delta: float) -> void:
	# 波次1：第2秒刷1只
	if _s6_wave == 0 and _s6_elapsed >= _s6_wave_times[0]:
		_s6_wave = 1
		_s6_spawned_this_wave = 0
		_s6_next_spawn_frames = 0
		_do_spawn_s6_boss()
		_s6_spawned_this_wave += 1
		print_debug("[S6] wave1 spawned 1/1")

	# 波次2：第30秒刷2只（不管前面杀没杀完）
	if _s6_wave == 1 and _s6_elapsed >= _s6_wave_times[1]:
		_s6_wave = 2
		_s6_spawned_this_wave = 0
		_s6_next_spawn_frames = int(1.5 * 60.0)
		print_debug("[S6] wave2 triggered at %.1fs" % _s6_elapsed)

	# 波次3：第75秒刷3只（不管前面杀没杀完）
	if _s6_wave == 2 and _s6_elapsed >= _s6_wave_times[2]:
		_s6_wave = 3
		_s6_spawned_this_wave = 0
		_s6_next_spawn_frames = int(1.5 * 60.0)
		print_debug("[S6] wave3 triggered at %.1fs" % _s6_elapsed)

	# 多只BOSS间隔生成（所有波次统一处理）
	if _s6_next_spawn_frames > 0:
		_s6_next_spawn_frames -= 1
	elif _s6_wave >= 1 and _s6_wave <= 3:
		var wave_idx: int = _s6_wave - 1
		var wave_count: int = _s6_wave_counts[wave_idx]
		if _s6_spawned_this_wave < wave_count:
			_do_spawn_s6_boss()
			_s6_spawned_this_wave += 1
			print_debug("[S6] wave%d spawned %d/%d" % [_s6_wave, _s6_spawned_this_wave, wave_count])
			if _s6_spawned_this_wave < wave_count:
				_s6_next_spawn_frames = int(0.5 * 60.0)

	# 检测全部通关：所有波次刷完且场上无BOSS存活
	if _s6_wave >= 1 and _s6_spawned_this_wave >= _s6_wave_counts[_s6_wave - 1] and _s6_bosses_alive <= 0:
		if _s6_wave == 3:
			_s6_wave = 4  # 全部完成
			s6_all_bosses_defeated.emit()
			print_debug("[S6] ALL BOSSES DEFEATED!")

func _do_spawn_s6_boss() -> void:
	print_debug("[SpawnManager] _do_spawn_s6_boss ENTER")
	if not is_instance_valid(game_manager) or not is_instance_valid(enemy_root):
		push_error("[SpawnManager] _do_spawn_s6_boss: invalid game_manager=%s or enemy_root=%s" % [is_instance_valid(game_manager), is_instance_valid(enemy_root)])
		return
	if not game_manager.player or not is_instance_valid(game_manager.player):
		push_error("[SpawnManager] _do_spawn_s6_boss: player invalid")
		return
	if boss_active:
		print_debug("[SpawnManager] _do_spawn_s6_boss: blocked by boss_active=true")
		return
	if _is_spawning_boss:
		print_debug("[SpawnManager] _do_spawn_s6_boss: blocked by _is_spawning_boss=true")
		return

	var chapter_id: int = game_manager.current_chapter_id
	var stage: StageData.StageInfo = game_manager.current_stage
	var boss_entry = BossRegistry.get_chapter_boss(chapter_id)
	print_debug("[SpawnManager] boss_entry=%s chapter=%d" % [boss_entry, chapter_id])

	var strength_mult: float = stage.strength_mult
	var speed_mult: float = 1.0
	if difficulty_scaler and difficulty_scaler.has_method("get_strength_mult"):
		strength_mult *= difficulty_scaler.get_strength_mult()
		speed_mult = difficulty_scaler.get_speed_mult()

	_pending_boss_entry = boss_entry
	_pending_chapter_id = chapter_id
	_pending_strength_mult = strength_mult
	_pending_speed_mult = speed_mult
	_pending_tonnage_chapter = chapter_id
	_pending_is_s6 = true

	print_debug("[SpawnManager] pending set: entry=%s chapter=%d" % [_pending_boss_entry, _pending_chapter_id])

	if boss_warning and boss_warning.has_method("hide_warning"):
		boss_warning.hide_warning()

	_show_boss_encounter(boss_entry)

func _spawn_boss(current_chapter_id: int) -> void:
	print_debug("[SpawnManager] _spawn_boss ENTER: chapter=%d boss_active=%s" % [current_chapter_id, boss_active])
	if boss_active:
		print_debug("[SpawnManager] _spawn_boss: blocked by boss_active=true")
		return
	if _is_spawning_boss:
		print_debug("[SpawnManager] _spawn_boss: blocked by _is_spawning_boss=true")
		return
	if not game_manager.player or not is_instance_valid(game_manager.player):
		push_error("[SpawnManager] _spawn_boss: player invalid")
		return

	var boss_entry = BossRegistry.get_chapter_boss(current_chapter_id)
	var strength_mult: float = game_manager.current_stage.strength_mult
	var speed_mult: float = 1.0
	if difficulty_scaler and difficulty_scaler.has_method("get_strength_mult"):
		strength_mult *= difficulty_scaler.get_strength_mult()
		speed_mult = difficulty_scaler.get_speed_mult()

	_pending_boss_entry = boss_entry
	_pending_chapter_id = current_chapter_id
	_pending_strength_mult = strength_mult
	_pending_speed_mult = speed_mult
	_pending_tonnage_chapter = current_chapter_id
	_pending_is_s6 = false

	kill_since_boss = 0

	print_debug("[SpawnManager] _spawn_boss: pending set entry=%s chapter=%d" % [_pending_boss_entry, _pending_chapter_id])

	if boss_warning and boss_warning.has_method("hide_warning"):
		boss_warning.hide_warning()

	_show_boss_encounter(boss_entry)


func _show_boss_encounter(boss_entry: BossEntry) -> void:
	if _is_spawning_boss:
		return
	_is_spawning_boss = true
	print_debug("[SpawnManager] _show_boss_encounter: entry=%s has_ui=%s" % [boss_entry, boss_encounter_ui != null])
	if boss_encounter_ui and boss_encounter_ui.has_method("show_encounter"):
		boss_encounter_ui.show_encounter(boss_entry)
		# 超时兜底：3秒后信号没触发则强制生成BOSS
		if get_tree() != null and boss_encounter_ui.has_signal("encounter_finished"):
			_spawn_timeout_timer = get_tree().create_timer(3.0)
			_spawn_timeout_timer.timeout.connect(_on_encounter_timeout, CONNECT_ONE_SHOT)
		else:
			# 没有信号时直接生成
			_is_spawning_boss = false
			_finish_boss_spawn()
	else:
		# 没有EncounterUI时直接生成BOSS
		_is_spawning_boss = false
		_finish_boss_spawn()


func _on_encounter_timeout() -> void:
	print_debug("[SpawnManager] _on_encounter_timeout: forcing boss spawn")
	_finish_boss_spawn()


func _finish_boss_spawn() -> void:
	print_debug("[SpawnManager] _finish_boss_spawn ENTER: boss_active=%s" % boss_active)
	# 防止重复调用（超时+信号同时触发时）
	if boss_active:
		print_debug("[SpawnManager] _finish_boss_spawn: blocked by boss_active=true")
		_is_spawning_boss = false
		return

	var entry = _pending_boss_entry
	if entry == null:
		push_error("[SpawnManager] _pending_boss_entry is null in _finish_boss_spawn")
		_is_spawning_boss = false
		return

	# 取消可能残留的超时计时器
	if _spawn_timeout_timer and is_instance_valid(_spawn_timeout_timer):
		_spawn_timeout_timer.timeout.disconnect(_on_encounter_timeout)
		_spawn_timeout_timer = null

	if _pending_is_s6:
		boss_active = true
		_s6_bosses_alive += 1
	else:
		boss_active = true

	var game_scene = game_manager.get_parent()
	if game_scene and game_scene.has_method("trigger_screen_shake"):
		game_scene.trigger_screen_shake(15.0, 0.3)
		var overlay = ColorRect.new()
		overlay.color = Color(1.0, 1.0, 1.0, 0.5)
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		game_scene.add_child(overlay)
		var t = overlay.create_tween()
		t.tween_property(overlay, "modulate:a", 0.0, 0.3)
		t.tween_callback(overlay.queue_free)

	var boss_scene = BossRegistry.get_boss_scene(entry.boss_id)
	print_debug("[SpawnManager] boss_scene=%s (entry.boss_id=%s)" % [boss_scene, entry.boss_id])
	var boss = boss_scene.instantiate()
	enemy_root.add_child(boss)

	var spawn_angle := randf_range(0, TAU)
	var spawn_dist := 500.0 if not _pending_is_s6 else randf_range(400.0, 700.0)
	boss.global_position = game_manager.player.global_position + Vector2.from_angle(spawn_angle) * spawn_dist

	var boss_stats := StageData.get_chapter_stats(_pending_chapter_id, "boss")

	boss.setup_from_entry(entry)
	boss.setup_boss(game_manager,
		boss_stats.hp * _pending_strength_mult,
		boss_stats.damage * _pending_strength_mult,
		boss_stats.speed * _pending_speed_mult,
		boss_stats.shield * _pending_strength_mult,
		_pending_tonnage_chapter)
	boss.enemy_dead.connect(_on_enemy_dead)

	print_debug("[SpawnManager] BOSS spawned: %s (chapter %d)" % [entry.boss_id, _pending_chapter_id])
	_is_spawning_boss = false


func _on_encounter_finished() -> void:
	if _spawn_timeout_timer and is_instance_valid(_spawn_timeout_timer):
		_spawn_timeout_timer.timeout.disconnect(_on_encounter_timeout)
		_spawn_timeout_timer = null
	_finish_boss_spawn()

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

	# 第6关时间波次BOSS处理
	if game_manager.current_stage != null and game_manager.current_stage.id == 6:
		_s6_bosses_alive -= 1
		if _s6_bosses_alive <= 0:
			boss_active = false
		# 不 emit boss_killed，避免触发掉落等副作用，直接返回
		return

	# 非第6关的普通BOSS流程
	if is_boss_phase:
		boss_active = false
		boss_remaining -= 1
		boss_killed.emit(boss_node)
	else:
		boss_active = false
		boss_killed.emit(boss_node)

func on_enemy_killed() -> void:
	kill_since_boss += 1

func reset() -> void:
	boss_active = false
	kill_since_boss = 0
	spawn_timer = 0.0
	_s6_wave = 0
	_s6_bosses_alive = 0
	_s6_spawned_this_wave = 0
	_s6_next_spawn_frames = 0
	_s6_elapsed = 0.0
	_debug_frame_count = 0
	if boss_warning and boss_warning.has_method("hide_warning"):
		boss_warning.hide_warning()

func is_s6_all_defeated() -> bool:
	return _s6_wave >= 4

func _on_enemy_dead(enemy: Node2D, enemy_type: String) -> void:
	enemy_dead.emit(enemy, enemy_type)
