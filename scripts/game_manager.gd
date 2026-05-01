extends Node2D

const DEBUG := false

func _debug(msg: String) -> void:
	if DEBUG:
		print("[GameManager] ", msg)

signal player_dead
signal upgrade_requested
signal game_paused(is_paused: bool)
signal game_ended(reason: String)
signal currency_changed(currency: int)
signal minerals_changed(minerals: int)

const ENEMY_MELEE_PATH = "res://scenes/EnemyMelee.tscn"
const ENEMY_SENTRY_PATH = "res://scenes/EnemySentry.tscn"
const ENEMY_RAVEN_PATH = "res://scenes/EnemyRaven.tscn"
const EXP_ORB_SCENE_PATH = "res://scenes/ExpOrb.tscn"
const BOSS_SCENE_PATH = "res://scenes/BossVoid.tscn"
const ShipData = preload("res://resources/ship_data.gd")

var player: Node2D
var enemy_root: Node2D
var bullet_root: Node2D
var exp_orb_root: Node2D
var damage_root: Node2D
var boss_warning: Node

var kill_count: int = 0
var total_kills: int = 0
var kill_since_boss: int = 0
var boss_active: bool = false
var boss_scene_path: Node2D

var enemy_hp: float = 30.0
var enemy_damage: float = 10.0
var enemy_move_speed: float = 100.0
var spawn_interval: float = 2.0
var spawn_timer: float = 0.0

var player_hp: int = 100
var player_max_hp: int = 100
var player_shield: float = 50.0
var player_shield_max: float = 50.0
var player_shield_regen: float = 4.0
var player_move_speed: float = 320.0
var player_damage: float = 15.0
var player_dodge: float = 0.1
var player_crit_rate: float = 0.05
var player_crit_mult: float = 1.5
var missile_range: float = 500.0
var missile_speed: float = 600.0
var player_lifesteal: float = 0.0
var xp_boost: float = 1.0

var spread_count: int = 1
var spread_angle: float = 6.0
var spread_damage_mult: float = 1.0
var missile_splash_radius: float = 0.0
var missile_splash_count: int = 0
var mobile_fire_mult: float = 1.0
var is_moving: bool = false

var silent_hunter_level: int = 0

var cannon_fire_interval: float = 1.2
var cannon_damage: float = 25.0
var cannon_pierce_count: int = 1
var cannon_explode_chance: float = 0.0
var cannon_bloodthirst: int = 0
var cannon_rush_level: int = 0
var cannon_vengeance_level: int = 0

var railgun_damage: float = 30.0
var railgun_speed: float = 1000.0
var railgun_range: float = 400.0
var railgun_fire_interval: float = 0.6
var railgun_crit_bonus: float = 0.0
var railgun_multi_count: int = 1

var laser_damage: float = 12.0
var laser_duration: float = 2.0
var laser_width: float = 16.0
var laser_fire_interval: float = 2.5
var laser_shield_mult: float = 1.0

var current_xp: float = 0.0
var xp_to_next_level: float = 10.0
var player_level: int = 1

var session_star_coin: int = 0
var session_minerals: int = 0

var combo_count: int = 0
var combo_timer: float = 0.0
var combo_timeout: float = 3.0
var combo_multiplier: float = 1.0

var enemy_rewards: Dictionary = {
	"melee": {"coin": 10, "mineral": 2},
	"sentry": {"coin": 14, "mineral": 3},
	"raven": {"coin": 18, "mineral": 4},
	"boss": {"coin": 250, "mineral": 40},
}

var is_game_over: bool = false
var is_paused: bool = false
var is_upgrading: bool = false

var time_remaining: float = 0.0
var has_timer: bool = false
const FIRST_RUN_DURATION: float = 300.0

var shield_regen_timer: float = 0.0
var lifesteal_timer: float = 0.0

var upgrade_counts: Dictionary = {}
var upgrade_pool: Array = []

func _ready() -> void:
	_setup_upgrade_pool()
	_setup_references()
	_spawn_player()

func _setup_upgrade_pool() -> void:
	upgrade_pool = [
		{"id": "damage", "name": "伤害强化", "desc": "所有武器伤害 x1.2", "max": 3, "weight": "high"},
		{"id": "shield_max", "name": "临时护盾", "desc": "shield_max +30，立即补满", "max": 3, "weight": "mid"},
		{"id": "fire_coverage", "name": "火力覆盖", "desc": "导弹哒哒哒连射（Lv.1=2发/Lv.2=3发/Lv.3=4发）", "max": 3, "weight": "high"},
		{"id": "shield_regen", "name": "护盾充能", "desc": "shield_regen x1.5", "max": 3, "weight": "mid"},
		{"id": "silent_hunter", "name": "静默猎手", "desc": "静止时射速+15%（fire_interval x0.85）", "max": 3, "weight": "low"},
		{"id": "precision_kill", "name": "精准猎杀", "desc": "导弹索敌范围 +100", "max": 3, "weight": "low"},
		{"id": "cannon_bloodthirst", "name": "嗜血残暴", "desc": "单次加农炮子弹数量 +1", "max": 3, "weight": "mid"},
		{"id": "cannon_rush", "name": "狂飙突进", "desc": "移动时射速 +15%", "max": 3, "weight": "low"},
		{"id": "cannon_vengeance", "name": "为了部落", "desc": "受伤时射速 +15%，持续2秒", "max": 3, "weight": "low"},
		{"id": "railgun_damage", "name": "一发入魂", "desc": "磁轨炮伤害 +20%", "max": 3, "weight": "low"},
		{"id": "railgun_crit", "name": "命中注定", "desc": "磁轨炮暴击率 +10%", "max": 3, "weight": "low"},
		{"id": "railgun_multi", "name": "多重射击", "desc": "单次射击次数 +1", "max": 3, "weight": "low"},
		{"id": "laser_duration", "name": "高能光束", "desc": "激光持续时间 +20%", "max": 3, "weight": "mid"},
		{"id": "laser_width", "name": "高效射击", "desc": "激光宽度 +20%", "max": 3, "weight": "low"},
		{"id": "laser_shield", "name": "护盾中和", "desc": "激光对护盾伤害 +20%", "max": 3, "weight": "low"},
	]

func _setup_references() -> void:
	var game_scene = get_parent()
	enemy_root = game_scene.get_node_or_null("EnemyRoot")
	bullet_root = game_scene.get_node_or_null("BulletRoot")
	exp_orb_root = game_scene.get_node_or_null("ExpOrbRoot")
	damage_root = game_scene.get_node_or_null("DamageRoot")
	boss_warning = game_scene.get_node_or_null("UIRoot/BossWarning")

func _apply_race_to_gm(race: RaceData) -> void:
	var ship = ShipData.get_ship(GameState.selected_ship_id)
	var ship_base_hp = ship.base_hp if ship else 100
	player_hp = ship_base_hp
	player_max_hp = ship_base_hp
	player_shield_max = race.shield_max
	player_shield = race.shield_max
	player_shield_regen = race.shield_regen
	player_move_speed = race.move_speed
	player_dodge = race.dodge_rate
	player_crit_rate = race.crit_rate
	player_crit_mult = race.crit_mult
	cannon_fire_interval = 1.2
	cannon_pierce_count = 1
	cannon_explode_chance = 0.0
	cannon_bloodthirst = 0
	cannon_rush_level = 0
	cannon_vengeance_level = 0
	railgun_damage = 30.0
	railgun_speed = 1000.0
	railgun_range = 400.0
	railgun_fire_interval = 0.6
	railgun_crit_bonus = 0.0
	railgun_multi_count = 1
	laser_damage = 12.0
	laser_duration = 2.0
	laser_width = 16.0
	laser_fire_interval = 2.5
	laser_shield_mult = 1.0

	for talent in race.talents:
		match talent.get("type"):
			"cannon_fire_rate":
				cannon_fire_interval *= (1.0 - talent.get("value", 0.0))
			"cannon_base_level":
				for i in range(int(talent.get("value", 1))):
					upgrade_counts["cannon_bloodthirst"] = upgrade_counts.get("cannon_bloodthirst", 0) + 1
					upgrade_counts["cannon_rush"] = upgrade_counts.get("cannon_rush", 0) + 1
					upgrade_counts["cannon_vengeance"] = upgrade_counts.get("cannon_vengeance", 0) + 1
					_apply_upgrade_effect("cannon_bloodthirst")
					_apply_upgrade_effect("cannon_rush")
					_apply_upgrade_effect("cannon_vengeance")
			"missile_range":
				missile_range *= (1.0 + talent.get("value", 0.0))
			"missile_base_level":
				for i in range(int(talent.get("value", 1))):
					upgrade_counts["fire_coverage"] = upgrade_counts.get("fire_coverage", 0) + 1
					upgrade_counts["silent_hunter"] = upgrade_counts.get("silent_hunter", 0) + 1
					upgrade_counts["precision_kill"] = upgrade_counts.get("precision_kill", 0) + 1
					_apply_upgrade_effect("fire_coverage")
					_apply_upgrade_effect("silent_hunter")
					_apply_upgrade_effect("precision_kill")
			"railgun_base_level":
				for i in range(int(talent.get("value", 1))):
					upgrade_counts["railgun_damage"] = upgrade_counts.get("railgun_damage", 0) + 1
					upgrade_counts["railgun_crit"] = upgrade_counts.get("railgun_crit", 0) + 1
					upgrade_counts["railgun_multi"] = upgrade_counts.get("railgun_multi", 0) + 1
					_apply_upgrade_effect("railgun_damage")
					_apply_upgrade_effect("railgun_crit")
					_apply_upgrade_effect("railgun_multi")
			"railgun_crit":
				railgun_crit_bonus += talent.get("value", 0.0)
			"laser_base_level":
				for i in range(int(talent.get("value", 1))):
					upgrade_counts["laser_duration"] = upgrade_counts.get("laser_duration", 0) + 1
					upgrade_counts["laser_width"] = upgrade_counts.get("laser_width", 0) + 1
					upgrade_counts["laser_shield"] = upgrade_counts.get("laser_shield", 0) + 1
					_apply_upgrade_effect("laser_duration")
					_apply_upgrade_effect("laser_width")
					_apply_upgrade_effect("laser_shield")
			"laser_width_duration":
				laser_width *= (1.0 + talent.get("value", 0.0))
				laser_duration *= (1.0 + talent.get("value", 0.0))
			_:
				pass
	_apply_armor_bonuses_to_gm()

func _apply_armor_bonuses_to_gm() -> void:
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE
	var armor = GameState.equipped_armor.get(ship_id, {})
	if armor is Dictionary and not armor.is_empty():
		player_shield_max += armor.get("shield_bonus", 0.0)
		player_shield_regen += armor.get("shield_regen_bonus", 0.0)
		player_shield = player_shield_max

func _apply_upgrade_effect(upgrade_id: String) -> void:
	match upgrade_id:
		"cannon_rf":
			cannon_fire_interval *= 0.8
		"cannon_pierce":
			cannon_pierce_count += 1
		"cannon_explode":
			cannon_explode_chance += 0.3
		"railgun_damage":
			railgun_damage *= 1.2
		"railgun_crit":
			railgun_crit_bonus += 0.1
		"railgun_multi":
			railgun_multi_count += 1
		"laser_duration":
			laser_duration *= 1.2
		"laser_width":
			laser_width *= 1.2
		"laser_shield":
			laser_shield_mult += 0.2
		"fire_coverage":
			spread_count += 1
		"silent_hunter":
			silent_hunter_level = upgrade_counts.get("silent_hunter", 0)
		"precision_kill":
			missile_range += 100.0

func _spawn_player() -> void:
	if player != null and is_instance_valid(player):
		return
	var player_scene_path = "res://scenes/Player.tscn"
	if not ResourceLoader.exists(player_scene_path):
		push_error("[GameManager] Player.tscn NOT FOUND!")
		return
	var ps = load(player_scene_path)
	if ps:
		var p = ps.instantiate()
		p.name = "Player"
		get_parent().get_node("PlayerRoot").add_child(p)
		player = p
		player.global_position = get_viewport_rect().size / 2.0
		_debug("Player spawned at: " + str(player.global_position))
		if player.has_method("set_game_manager"):
			player.set_game_manager(self)
		var race = RaceData.get_race(GameState.selected_race_id)
		if race and player.has_method("apply_race_data"):
			player.apply_race_data(race)
		if race:
			_apply_race_to_gm(race)
	else:
		push_error("[GameManager] failed to load Player scene")

func start_run_timer() -> void:
	if GameState.first_run:
		has_timer = true
		time_remaining = FIRST_RUN_DURATION
		GameState.on_run_started()
	else:
		has_timer = false
		time_remaining = 0.0

func _process(delta: float) -> void:
	if is_game_over or is_paused or is_upgrading:
		return

	_update_timer(delta)
	_spawn_enemies(delta)
	_update_shield_regen(delta)
	_update_lifesteal(delta)
	_update_combo(delta)
	_check_boss_warning()

func _update_timer(delta: float) -> void:
	if not has_timer:
		return
	if time_remaining <= 0.0:
		return
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_notify_hud_update()
		_on_timer_expired()

func _on_timer_expired() -> void:
	is_game_over = true
	get_tree().paused = true
	game_ended.emit("timeout")
	_show_settlement("timeout")

func _show_settlement(reason: String) -> void:
	var game_scene = get_parent()
	if game_scene and game_scene.has_method("_show_settlement_screen"):
		game_scene._show_settlement_screen(reason)

func _update_combo(delta: float) -> void:
	if combo_count > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0
			combo_multiplier = _get_combo_multiplier()
			_notify_hud_update()

func _spawn_enemies(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_enemy()

func _spawn_enemy() -> void:
	if not player or not is_instance_valid(player):
		return

	if boss_active:
		if randf() < 0.5:
			return

	var enemy_path = _choose_enemy_type()
	if enemy_path == "":
		return
	if not ResourceLoader.exists(enemy_path):
		push_error("[GameManager] Enemy scene not found: " + enemy_path)
		return

	var enemy_scene = load(enemy_path)
	var enemy = enemy_scene.instantiate()
	enemy_root.add_child(enemy)

	var spawn_distance = randf_range(600.0, 900.0)
	var spawn_angle = randf_range(0, TAU)
	enemy.global_position = player.global_position + Vector2.from_angle(spawn_angle) * spawn_distance

	match enemy_path:
		ENEMY_MELEE_PATH:
			enemy.setup_enemy(self, enemy_hp, enemy_damage, enemy_move_speed)
			enemy.enemy_dead.connect(_on_enemy_dead)
		ENEMY_SENTRY_PATH:
			enemy.setup_enemy(self, enemy_hp * 0.7, enemy_damage * 0.8, 60.0)
			enemy.enemy_dead.connect(_on_enemy_dead)
		ENEMY_RAVEN_PATH:
			enemy.setup_enemy(self, enemy_hp * 0.5, enemy_damage * 1.5, 200.0)
			enemy.enemy_dead.connect(_on_enemy_dead)

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

func _check_boss_warning() -> void:
	if boss_active:
		return
	if kill_since_boss >= 45 and kill_since_boss < 50:
		if boss_warning and boss_warning.has_method("show_warning"):
			boss_warning.show_warning()
	elif kill_since_boss >= 50:
		_spawn_boss()

func _spawn_boss() -> void:
	SoundManager.play_sfx("boss_appear")
	SoundManager.play_music("battle_boss")
	if not ResourceLoader.exists(BOSS_SCENE_PATH):
		push_error("[GameManager] BossVoid.tscn NOT FOUND!")
		return
	if not player or not is_instance_valid(player):
		return

	boss_active = true
	kill_since_boss = 0

	if boss_warning and boss_warning.has_method("hide_warning"):
		boss_warning.hide_warning()

	var game_scene = get_parent()
	if game_scene and game_scene.has_method("trigger_screen_shake"):
		game_scene.trigger_screen_shake(15.0, 0.3)
		var overlay = ColorRect.new()
		overlay.color = Color(1.0, 1.0, 1.0, 0.5)
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		game_scene.add_child(overlay)
		var t = game_scene.create_tween()
		t.tween_property(overlay, "modulate:a", 0.0, 0.3)
		t.tween_callback(overlay.queue_free)

	var boss_scene = load(BOSS_SCENE_PATH)
	var boss = boss_scene.instantiate()
	enemy_root.add_child(boss)

	var spawn_dist = 500.0
	var spawn_angle = randf_range(0, TAU)
	boss.global_position = player.global_position + Vector2.from_angle(spawn_angle) * spawn_dist

	boss.setup_boss(self)
	boss.enemy_dead.connect(_on_enemy_dead)

func on_boss_killed(boss_node: Node2D) -> void:
	SoundManager.play_music("battle")
	boss_active = false
	kill_since_boss = 0

	if boss_warning and boss_warning.has_method("hide_warning"):
		boss_warning.hide_warning()

	var reward = enemy_rewards.get("boss", {"coin": 250, "mineral": 40})
	var reward_coin = int(reward["coin"])
	var reward_mineral = int(reward["mineral"])
	session_star_coin += reward_coin
	session_minerals += reward_mineral

	_notify_hud_update()

func _update_shield_regen(delta: float) -> void:
	shield_regen_timer += delta
	if shield_regen_timer >= 1.0:
		shield_regen_timer = 0.0
		player_shield = min(player_shield + player_shield_regen, player_shield_max)
		_notify_hud_update()

func _update_lifesteal(delta: float) -> void:
	if player_lifesteal <= 0.0:
		return
	lifesteal_timer += delta
	if lifesteal_timer >= 1.0:
		lifesteal_timer = 0.0
		player_hp = mini(player_hp + int(player_lifesteal), player_max_hp)
		_notify_hud_update()

func _notify_hud_update() -> void:
	var game_scene = get_parent()
	if game_scene and game_scene.has_node("UIRoot/HUD"):
		var hud = game_scene.get_node("UIRoot/HUD")
		hud.update_display(
			player_hp, player_max_hp, player_shield, player_shield_max,
			GameState.star_coin, GameState.minerals_low + GameState.minerals_mid + GameState.minerals_high,
			kill_count, current_xp, xp_to_next_level, player_level
		)

func _get_combo_multiplier() -> float:
	if combo_count >= 30:
		return 3.0
	elif combo_count >= 20:
		return 2.5
	elif combo_count >= 10:
		return 2.0
	elif combo_count >= 5:
		return 1.5
	return 1.0

func _on_enemy_dead(enemy: Node2D, enemy_type: String) -> void:
	match enemy_type:
		"boss":
			on_boss_killed(enemy)
		_:
			on_enemy_killed(enemy, enemy_type)

func on_enemy_killed(enemy: Node2D, enemy_type: String) -> void:
	kill_count += 1
	total_kills += 1
	kill_since_boss += 1

	combo_count += 1
	combo_timer = combo_timeout
	combo_multiplier = _get_combo_multiplier()

	var reward = enemy_rewards.get(enemy_type, {"coin": 5, "mineral": 2})
	var reward_coin = int(reward["coin"] * combo_multiplier)
	var reward_mineral = int(reward["mineral"] * combo_multiplier)
	session_star_coin += reward_coin
	session_minerals += reward_mineral

	_spawn_exp_orb(enemy.global_position)

	if kill_since_boss > 0 and kill_since_boss % 20 == 0:
		_difficulty_scale()

func _spawn_exp_orb(pos: Vector2) -> void:
	if not ResourceLoader.exists(EXP_ORB_SCENE_PATH):
		return
	var orb_scene = load(EXP_ORB_SCENE_PATH)
	var orb = orb_scene.instantiate()
	orb.set_game_manager(self)
	orb.global_position = pos
	exp_orb_root.call_deferred("add_child", orb)

func _difficulty_scale() -> void:
	enemy_hp *= 1.1
	spawn_interval = maxf(0.8, spawn_interval - 0.1)

func on_exp_orb_collected(amount: float) -> void:
	_debug("on_exp_orb_collected: amount=" + str(amount) + " current_xp=" + str(current_xp))
	current_xp += amount * xp_boost
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
	is_upgrading = true
	get_tree().paused = true
	upgrade_requested.emit()

func _get_equipped_weapon_id() -> int:
	if player and is_instance_valid(player) and player.has_method("get_primary_weapon"):
		var pw = player.get_primary_weapon()
		if pw:
			return pw.weapon_id
	return 0

func apply_upgrade(upgrade_id: String) -> void:
	_debug("apply_upgrade: " + upgrade_id + " upgrade_counts=" + str(upgrade_counts))

	if not upgrade_counts.has(upgrade_id):
		upgrade_counts[upgrade_id] = 0

	var upgrade_data = upgrade_pool.filter(func(u): return u["id"] == upgrade_id)
	if upgrade_data.is_empty():
		_debug("upgrade not found in pool!")
		is_upgrading = false
		get_tree().paused = false
		return

	var data = upgrade_data[0]
	if upgrade_counts[upgrade_id] >= data["max"]:
		_debug("upgrade max reached!")
		is_upgrading = false
		get_tree().paused = false
		return

	upgrade_counts[upgrade_id] += 1

	match upgrade_id:
		"damage":
			player_damage *= 1.2
		"shield_max":
			player_shield_max += 30.0
			player_shield = player_shield_max
		"fire_coverage":
			spread_count += 1
		"shield_regen":
			player_shield_regen *= 1.5
		"silent_hunter":
			silent_hunter_level = upgrade_counts["silent_hunter"]
		"precision_kill":
			missile_range += 100.0
		"cannon_bloodthirst":
			cannon_bloodthirst += 1
		"cannon_rush":
			cannon_rush_level = upgrade_counts["cannon_rush"]
		"cannon_vengeance":
			cannon_vengeance_level = upgrade_counts["cannon_vengeance"]
		"railgun_damage":
			railgun_damage *= 1.2
		"railgun_crit":
			railgun_crit_bonus += 0.1
		"railgun_multi":
			railgun_multi_count += 1
		"laser_duration":
			laser_duration *= 1.2
		"laser_width":
			laser_width *= 1.2
		"laser_shield":
			laser_shield_mult += 0.2

	if player and is_instance_valid(player) and player.has_method("sync_from_game_manager"):
		player.sync_from_game_manager(self)

	is_upgrading = false
	get_tree().paused = false
	_notify_hud_update()

func on_player_take_damage(damage: float) -> void:
	if randf() < player_dodge:
		return

	var final_damage = damage
	var is_crit = randf() < player_crit_rate
	if is_crit:
		final_damage *= player_crit_mult

	if player_shield > 0:
		var shield_dmg = minf(player_shield, final_damage)
		player_shield -= shield_dmg
		final_damage -= shield_dmg
		if shield_dmg > 0:
			if player_shield <= 0:
				SoundManager.play_sfx("shield_break")
			else:
				SoundManager.play_sfx("shield_hit")

	if final_damage > 0:
		SoundManager.play_sfx("player_hurt")
		player_hp -= int(final_damage)
		var game_scene = get_parent()
		if game_scene and game_scene.has_method("trigger_screen_shake"):
			game_scene.trigger_screen_shake(5.0, 0.15)

	if final_damage > 0:
		_spawn_damage_number(player.global_position if player and is_instance_valid(player) else Vector2.ZERO, final_damage, is_crit, true)

	_notify_hud_update()

	if player_hp <= 0:
		player_hp = 0
		_notify_hud_update()
		_on_player_dead()

func _spawn_damage_number(world_pos: Vector2, amount: float, is_crit: bool, enemy_dmg: bool) -> void:
	if not damage_root or not is_instance_valid(damage_root):
		return
	if not ResourceLoader.exists("res://scenes/DamageNumber.tscn"):
		return
	var scene = load("res://scenes/DamageNumber.tscn")
	var node = scene.instantiate()
	damage_root.add_child(node)
	node.setup(world_pos, amount, is_crit, enemy_dmg)

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

func on_retreat() -> void:
	is_game_over = true
	get_tree().paused = true
	game_ended.emit("retreat")

func on_self_destruct() -> void:
	is_game_over = true
	get_tree().paused = true
	game_ended.emit("self_destruct")

func reset_for_new_run() -> void:
	is_game_over = false
	is_paused = false
	is_upgrading = false
	kill_count = 0
	total_kills = 0
	kill_since_boss = 0
	boss_active = false
	enemy_hp = 30.0
	enemy_damage = 10.0
	enemy_move_speed = 100.0
	spawn_interval = 2.0
	spawn_timer = 0.0
	player_hp = 100
	player_max_hp = 100
	player_shield = 50.0
	player_shield_max = 50.0
	player_shield_regen = 4.0
	player_move_speed = 320.0
	player_damage = 15.0
	player_dodge = 0.1
	player_crit_rate = 0.05
	player_crit_mult = 1.5
	missile_range = 500.0
	missile_speed = 600.0
	player_lifesteal = 0.0
	xp_boost = 1.0
	spread_count = 1
	spread_angle = 6.0
	spread_damage_mult = 1.0
	missile_splash_radius = 0.0
	missile_splash_count = 0
	mobile_fire_mult = 1.0
	is_moving = false
	silent_hunter_level = 0
	cannon_fire_interval = 1.2
	cannon_damage = 25.0
	cannon_pierce_count = 1
	cannon_explode_chance = 0.0
	cannon_bloodthirst = 0
	cannon_rush_level = 0
	cannon_vengeance_level = 0
	railgun_damage = 30.0
	railgun_speed = 1000.0
	railgun_range = 400.0
	railgun_fire_interval = 0.6
	railgun_crit_bonus = 0.0
	railgun_multi_count = 1
	laser_damage = 12.0
	laser_duration = 2.0
	laser_width = 16.0
	laser_fire_interval = 2.5
	laser_shield_mult = 1.0
	current_xp = 0.0
	xp_to_next_level = 10.0
	player_level = 1
	session_star_coin = 0
	session_minerals = 0
	shield_regen_timer = 0.0
	lifesteal_timer = 0.0
	upgrade_counts = {}
	upgrade_pool = []
	_setup_upgrade_pool()

	if boss_warning and boss_warning.has_method("hide_warning"):
		boss_warning.hide_warning()

	for child in enemy_root.get_children():
		child.queue_free()
	for child in bullet_root.get_children():
		child.queue_free()
	for child in exp_orb_root.get_children():
		child.queue_free()

	has_timer = false
	time_remaining = 0.0

	if player and is_instance_valid(player):
		if player.has_method("init_weapons"):
			player.init_weapons()
		_apply_race_to_gm(RaceData.get_race(GameState.selected_race_id))
		player.sync_from_game_manager(self)
		player.global_position = get_viewport_rect().size / 2.0
		if player.has_method("reset_state"):
			player.reset_state()
	else:
		_spawn_player()

	start_run_timer()
	get_tree().paused = false
	_notify_hud_update()
