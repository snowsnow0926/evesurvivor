extends Node2D

const DEBUG := false

func _debug(msg: String) -> void:
	if DEBUG:
		print("[GameManager] ", msg)

signal player_dead
signal upgrade_requested
signal game_paused(is_paused: bool)
signal game_ended(reason: String)

const _SCENE_PLAYER: PackedScene = preload("res://scenes/Player.tscn")
const _SCENE_DAMAGE_NUMBER: PackedScene = preload("res://scenes/DamageNumber.tscn")

const RaceData = preload("res://resources/race_data.gd")
const ShipData = preload("res://resources/ship_data.gd")
const StageData = preload("res://resources/stage_data.gd")
const PlayerStats = preload("res://resources/player_stats.gd")

var player: Node2D
var enemy_root: Node2D
var bullet_root: Node2D
var exp_orb_root: Node2D
var damage_root: Node2D
var boss_warning: Node

var player_stats: PlayerStats
var spawn_manager: SpawnManager
var upgrade_system: UpgradeSystem
var difficulty_scaler: DifficultyScaler
var loot_system: LootSystem

var upgrade_counts: Dictionary:
	get: return upgrade_system.upgrade_counts if upgrade_system else {}

var combo_count: int:
	get: return difficulty_scaler.combo_count if difficulty_scaler else 0

var upgrade_pool: Array:
	get: return upgrade_system.upgrade_pool if upgrade_system else []

var session_star_coin: int:
	get: return loot_system.session_star_coin if loot_system else 0

var session_minerals: int:
	get: return loot_system.session_minerals if loot_system else 0

var kill_count: int = 0
var total_kills: int = 0
var elites_killed_this_run: int = 0
var is_game_over: bool = false
var is_paused: bool = false
var is_upgrading: bool = false
var game_speed: float = 1.0

var current_xp: float = 0.0
var xp_to_next_level: float = 10.0
var player_level: int = 1

var time_remaining: float = 0.0
var has_timer: bool = false
var is_unlimited_mode: bool = false
var run_time_elapsed: float = 0.0
var is_boss_infinite: bool = false
var _timer_expired_once: bool = false
const FIRST_RUN_DURATION: float = 300.0
var _unlimited_start_real_time: int = 0
var _timer_start_real_time: int = 0
var stage_duration: float = 0.0

var current_stage: StageData.StageInfo
var current_chapter_id: int = 1

func _ready() -> void:
	_init_subsystems()
	_setup_references()
	_spawn_player()

func _init_subsystems() -> void:
	player_stats = PlayerStats.new()
	spawn_manager = SpawnManager.new(self, player_stats)
	upgrade_system = UpgradeSystem.new(player_stats)
	difficulty_scaler = DifficultyScaler.new()
	loot_system = LootSystem.new(self)

	difficulty_scaler.setup(spawn_manager)
	upgrade_system.upgrade_requested.connect(_on_upgrade_requested)
	upgrade_system.apply_research_bonuses()

	# 监听核心词条升级，实时同步到玩家属性
	CoreEquipManager.skill_upgraded.connect(_on_core_skill_upgraded)
	# 监听核心切换，重新同步玩家属性
	CoreEquipManager.core_equipped.connect(_on_core_equipped)

func _setup_references() -> void:
	var game_scene = get_parent()
	enemy_root = game_scene.get_node_or_null("EnemyRoot")
	bullet_root = game_scene.get_node_or_null("BulletRoot")
	exp_orb_root = game_scene.get_node_or_null("ExpOrbRoot")
	damage_root = game_scene.get_node_or_null("DamageRoot")
	boss_warning = game_scene.get_node_or_null("UIRoot/BossWarning")
	var boss_encounter_ui = game_scene.get_node_or_null("UIRoot/BossEncounterUI")

	spawn_manager.setup_references(enemy_root, exp_orb_root, boss_warning, boss_encounter_ui)
	spawn_manager.enemy_dead.connect(_on_enemy_dead)
	spawn_manager.boss_killed.connect(_on_boss_killed)
	spawn_manager.s6_all_bosses_defeated.connect(_on_s6_all_bosses_defeated)

func _spawn_player() -> void:
	if player != null and is_instance_valid(player):
		return
	var ps = _SCENE_PLAYER
	if ps:
		var p = ps.instantiate()
		p.name = "Player"
		get_parent().get_node("PlayerRoot").add_child(p)
		player = p
		player.global_position = get_viewport_rect().size / 2.0
		_debug("Player spawned at: " + str(player.global_position))
		if player.has_method("set_game_manager"):
			player.set_game_manager(self)
		if player.has_method("set_player_stats"):
			player.set_player_stats(player_stats)
		var race = RaceData.get_race(GameState.selected_race_id)
		if race and player.has_method("apply_race_data"):
			player.apply_race_data(race)
		if race:
			_apply_race_to_player_stats(race)
			if player.has_method("sync_from_player_stats"):
				player.sync_from_player_stats(player_stats)
	else:
		push_error("[GameManager] failed to load Player scene")

func _apply_race_to_player_stats(race: RaceData) -> void:
	var ship = ShipData.get_ship(GameState.selected_ship_id)
	var ship_base_hp = ship.base_hp if ship else 100
	player_stats.max_hp = ship_base_hp + race.base_hp
	player_stats.hp = player_stats.max_hp
	player_stats.shield_max = ship.base_shield + race.shield_max
	player_stats.shield = player_stats.shield_max
	player_stats.shield_regen = ship.base_shield_regen + race.shield_regen
	player_stats.hp_regen = 0.0
	player_stats.move_speed = race.move_speed
	player_stats.dodge = race.dodge_rate
	player_stats.crit_rate = race.crit_rate
	player_stats.crit_mult = race.crit_mult

	# 核心系统接管种族天赋注入
	CoreEquipManager.equip_starting_core(race.race_key)
	player_stats.sync_from_core(CoreEquipManager.get_equipped_core_id())

	_apply_armor_bonuses()

func _apply_armor_bonuses() -> void:
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE
	var armor_list: Array = GameState.equipped_armor.get(ship_id, [])
	if not (armor_list is Array):
		armor_list = []
	for armor in armor_list:
		if armor is Dictionary:
			player_stats.shield_max += armor.get("shield_bonus", 0.0)
			player_stats.shield_regen += armor.get("shield_regen_bonus", 0.0)
			player_stats.hp_regen += armor.get("hp_regen_bonus", 0.0)
	player_stats.shield = player_stats.shield_max

func setup_for_stage(chapter_id: int, stage_id: int) -> void:
	current_chapter_id = chapter_id
	current_stage = StageData.get_stage(chapter_id, stage_id)
	if current_stage == null:
		push_warning("[GameManager] Stage not found, using defaults")
		current_stage = StageData.get_stage(1, 1)

	print_debug("[GameManager] setup_for_stage: chapter=%d stage=%d stage.type=%s stage.id=%d" % [chapter_id, stage_id, current_stage.type, current_stage.id])

	spawn_manager.setup_stage(chapter_id, stage_id, player_level)
	difficulty_scaler.setup_stage(current_stage.strength_mult, current_stage.density_mult, player_level)
	set_game_speed(1.0)
	loot_system.reset()

	if current_stage.has_timer:
		has_timer = true
		is_unlimited_mode = GameState.is_stage_cleared(chapter_id, stage_id)
		if is_unlimited_mode:
			time_remaining = 0.0
			run_time_elapsed = 0.0
			_unlimited_start_real_time = Time.get_ticks_msec()
		else:
			if stage_id == 6:
				time_remaining = 480.0
			else:
				time_remaining = FIRST_RUN_DURATION
			_timer_start_real_time = Time.get_ticks_msec()
	else:
		has_timer = false
		is_unlimited_mode = false
		time_remaining = 0.0

	_debug("setup_for_stage: chapter=%d stage=%d" % [chapter_id, stage_id])

func start_run_timer() -> void:
	if current_stage != null and current_stage.has_timer:
		has_timer = true
		is_unlimited_mode = GameState.is_stage_cleared(current_chapter_id, current_stage.id)
		if is_unlimited_mode:
			time_remaining = 0.0
			run_time_elapsed = 0.0
			_unlimited_start_real_time = Time.get_ticks_msec()
		else:
			if current_stage.id == 6:
				time_remaining = 480.0
			else:
				time_remaining = FIRST_RUN_DURATION
			_timer_start_real_time = Time.get_ticks_msec()
		elites_killed_this_run = 0
		_timer_expired_once = false
		is_boss_infinite = false
		GameState.on_run_started()
	else:
		has_timer = false
		is_unlimited_mode = false
		time_remaining = 0.0
		_timer_expired_once = false
		is_boss_infinite = false

func _process(delta: float) -> void:
	if is_game_over or is_upgrading:
		return
	# time_scale handles delta scaling for all child nodes automatically
	# NOTE: delta here is already scaled by Engine.time_scale, do NOT multiply by game_speed again
	_update_timer(delta)
	spawn_manager.update_spawning(delta, current_stage, current_chapter_id, player_level)
	player_stats.update_regen(delta)
	difficulty_scaler.update_combo(delta)
	_notify_hud_update()

func _update_timer(delta: float) -> void:
	if not has_timer:
		return
	if is_paused:
		return
	if is_unlimited_mode:
		run_time_elapsed += delta
		_notify_hud_update()
		return
	if time_remaining <= 0.0:
		return
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_notify_hud_update()
		_on_timer_expired()

func _on_timer_expired() -> void:
	# 第6关：时间到 = 任务失败
	if current_stage != null and current_stage.id == 6:
		is_game_over = true
		get_tree().paused = true
		game_ended.emit("timeout")
		return
	# 前五关：时间到 = 撤离成功（坚持5分钟过关）
	is_game_over = true
	get_tree().paused = true
	game_ended.emit("retreat")

func _on_s6_all_bosses_defeated() -> void:
	# 第6关全部BOSS被击杀 → 胜利
	if current_stage != null and current_stage.id == 6:
		is_game_over = true
		get_tree().paused = true
		game_ended.emit("s6_victory")
		return


func _on_enemy_dead(enemy: Node2D, enemy_type: String) -> void:
	match enemy_type:
		"boss":
			spawn_manager.on_boss_killed(enemy)
		_:
			on_enemy_killed(enemy, enemy_type)

func on_enemy_killed(enemy: Node2D, enemy_type: String) -> void:
	kill_count += 1
	total_kills += 1
	spawn_manager.on_enemy_killed()
	difficulty_scaler.on_enemy_killed()

	if enemy.get("is_elite"):
		elites_killed_this_run += 1

	var reward_coin = loot_system.on_enemy_killed(enemy, enemy_type)
	GameState.star_coin += reward_coin
	spawn_manager.spawn_exp_orb(enemy.global_position)
	loot_system.try_drop_equipment(enemy)

	if spawn_manager.kill_since_boss > 0 and spawn_manager.kill_since_boss % 20 == 0:
		difficulty_scaler.on_difficulty_tick()

func _on_boss_killed(boss_node: Node2D) -> void:
	loot_system.spawn_boss_loot(boss_node)
	var prev = loot_system.session_star_coin
	loot_system.on_boss_killed(boss_node)
	GameState.star_coin += loot_system.session_star_coin - prev

	if spawn_manager.is_boss_phase:
		if spawn_manager.boss_remaining <= 0:
			is_game_over = true
			get_tree().paused = true
			game_ended.emit("retreat")
			_show_settlement("retreat")
	_notify_hud_update()

func _notify_hud_update() -> void:
	var game_scene = get_parent()
	if game_scene and game_scene.has_node("UIRoot/HUD"):
		var hud = game_scene.get_node("UIRoot/HUD")
		hud.update_display(
			player_stats.hp, player_stats.max_hp, player_stats.shield, player_stats.shield_max,
			GameState.star_coin, GameState.minerals_low + GameState.minerals_mid + GameState.minerals_high,
			kill_count, current_xp, xp_to_next_level, player_level, combo_count
		)

func _show_settlement(reason: String) -> void:
	var game_scene = get_parent()
	if game_scene and game_scene.has_method("_show_settlement_screen"):
		game_scene._show_settlement_screen(reason)

func on_exp_orb_collected(amount: float) -> void:
	current_xp += amount * player_stats.xp_boost
	CoreEquipManager.add_xp(int(amount * player_stats.xp_boost))
	var leveled_up = false
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		xp_to_next_level *= 1.5
		player_level += 1
		leveled_up = true
	_notify_hud_update()
	if leveled_up:
		_trigger_upgrade()

func _trigger_upgrade() -> void:
	if CoreEquipManager.get_equipped_core_id().is_empty():
		return
	var candidates = CoreEquipManager.get_available_upgrades(CoreEquipManager.get_equipped_core_id())
	if candidates.is_empty():
		is_upgrading = false
		get_tree().paused = false
		return
	is_upgrading = true
	get_tree().paused = true
	upgrade_system.trigger_upgrade_request()

func _on_upgrade_requested() -> void:
	upgrade_requested.emit()

func on_player_take_damage(damage: float) -> void:
	player_stats.is_injured = true
	player_stats.injured_timer = PlayerStats.INJURED_DURATION
	var final_damage = damage
	# 护盾受击：伤害先扣护盾，护盾归零后再扣HP（无额外减伤系数）
	if player_stats.shield > 0:
		var shield_dmg = minf(player_stats.shield, final_damage)
		player_stats.shield -= shield_dmg
		final_damage -= shield_dmg
		if shield_dmg > 0:
			if player_stats.shield <= 0:
				SoundManager.play_sfx("shield_break")
			else:
				SoundManager.play_sfx("shield_hit")

	if final_damage > 0:
		SoundManager.play_sfx("player_hurt")
		player_stats.hp -= int(final_damage)
		var game_scene = get_parent()
		if game_scene and game_scene.has_method("trigger_screen_shake"):
			game_scene.trigger_screen_shake(5.0, 0.15)
		var world_pos = player.global_position if player and is_instance_valid(player) else Vector2.ZERO
		_spawn_damage_number(world_pos, final_damage, false, true)

	_notify_hud_update()

	if player_stats.hp <= 0:
		player_stats.hp = 0
		_notify_hud_update()
		_on_player_dead()

func _spawn_damage_number(world_pos: Vector2, amount: float, is_crit: bool, enemy_dmg: bool) -> void:
	if not damage_root or not is_instance_valid(damage_root):
		return
	var node = _SCENE_DAMAGE_NUMBER.instantiate()
	damage_root.add_child(node)
	node.setup(world_pos, amount, is_crit, enemy_dmg)

func apply_upgrade(upgrade_id: String) -> void:
	is_upgrading = false
	get_tree().paused = false
	var core_id = CoreEquipManager.get_equipped_core_id()
	if core_id.is_empty():
		# 无核心时回退旧升级系统（理论上不应发生，equip_starting_core 总会装备一个核心）
		var success = upgrade_system.apply_upgrade(upgrade_id)
		if success and player and is_instance_valid(player) and player.has_method("sync_from_player_stats"):
			player.sync_from_player_stats(player_stats)
		_notify_hud_update()
		return
	var success = CoreEquipManager.upgrade_skill(core_id, upgrade_id)
	_notify_hud_update()
	if not success:
		pass  # 已达等级上限，静默忽略


func _on_core_skill_upgraded(core_id: String, skill_id: String, new_level: int) -> void:
	if core_id != CoreEquipManager.get_equipped_core_id():
		return
	# 同步到 upgrade_system.upgrade_counts，使 HUD 升级面板能正常显示
	upgrade_system.upgrade_counts[skill_id] = new_level
	player_stats.sync_from_core(core_id)
	if player and is_instance_valid(player) and player.has_method("sync_from_player_stats"):
		player.sync_from_player_stats(player_stats)


func _on_core_equipped(core_id: String) -> void:
	player_stats.sync_from_core(core_id)
	if player and is_instance_valid(player) and player.has_method("sync_from_player_stats"):
		player.sync_from_player_stats(player_stats)


func _on_player_dead() -> void:
	SoundManager.play_sfx("player_death")
	if is_game_over:
		return
	is_game_over = true
	get_tree().paused = true
	game_ended.emit("dead")
	player_dead.emit()

func trigger_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	game_paused.emit(is_paused)

func set_game_speed(speed: float) -> void:
	game_speed = speed
	Engine.time_scale = game_speed
	game_paused.emit(is_paused)

func on_retreat() -> void:
	is_game_over = true
	get_tree().paused = true
	game_ended.emit("retreat")

func on_self_destruct() -> void:
	is_game_over = true
	get_tree().paused = true
	game_ended.emit("self_destruct")

func get_session_loot() -> Array:
	return loot_system.get_session_loot()

func try_drop_equipment(enemy: Node2D) -> void:
	loot_system.try_drop_equipment(enemy)

func spawn_boss_loot(boss_node: Node2D) -> void:
	loot_system.spawn_boss_loot(boss_node)

func grant_loot_to_player() -> Array:
	return loot_system.grant_loot_to_player()

func reset_for_new_run() -> void:
	is_game_over = false
	is_paused = false
	is_upgrading = false
	game_speed = 1.0
	kill_count = 0
	total_kills = 0
	elites_killed_this_run = 0
	current_xp = 0.0
	xp_to_next_level = 10.0
	player_level = 1
	time_remaining = 0.0
	has_timer = false
	stage_duration = 0.0
	_timer_expired_once = false
	is_boss_infinite = false

	spawn_manager.reset()
	difficulty_scaler.reset()
	player_stats.full_reset()
	upgrade_system.reset()
	loot_system.reset()

	setup_for_stage(current_chapter_id, current_stage.id if current_stage else 1)
	upgrade_system.apply_research_bonuses()

	# 重新同步核心词条效果
	var core_id = CoreEquipManager.get_equipped_core_id()
	if not core_id.is_empty():
		player_stats.sync_from_core(core_id)

	for child in enemy_root.get_children():
		child.queue_free()
	for child in bullet_root.get_children():
		child.queue_free()
	for child in exp_orb_root.get_children():
		child.queue_free()

	if player and is_instance_valid(player):
		if player.has_method("init_weapons"):
			player.init_weapons()
		_apply_race_to_player_stats(RaceData.get_race(GameState.selected_race_id))
		if player.has_method("sync_from_player_stats"):
			player.sync_from_player_stats(player_stats)
		player.global_position = get_viewport_rect().size / 2.0
		if player.has_method("reset_state"):
				player.reset_state()
	else:
		_spawn_player()

	start_run_timer()
	get_tree().paused = false
	Engine.time_scale = 1.0
	game_speed = 1.0
	_notify_hud_update()
