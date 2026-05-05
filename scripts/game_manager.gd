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
const StageData = preload("res://resources/stage_data.gd")
const WeaponData = preload("res://resources/weapon_data.gd")
const EquipmentData = preload("res://resources/equipment_data.gd")
const ShopItemData = preload("res://resources/shop_data.gd")

var player: Node2D
var enemy_root: Node2D
var bullet_root: Node2D
var exp_orb_root: Node2D
var damage_root: Node2D
var effect_root: Node2D
var effect_manager: Node
var boss_warning: Node

var kill_count: int = 0
var total_kills: int = 0
var kill_since_boss: int = 0
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

var laser_width: float = 16.0
var laser_duration: float = 2.0
var laser_shield_penetration_mult: float = 1.0
var race_talent_counts: Dictionary = {}

func get_upgrade_total_level(key: String) -> int:
	return upgrade_counts.get(key, 0) + race_talent_counts.get(key, 0) + GameState.research_progress.get(key, 0)

var current_xp: float = 0.0
var xp_to_next_level: float = 10.0
var player_level: int = 1

var session_star_coin: int = 0
var session_minerals_low: int = 0
var session_minerals_mid: int = 0
var session_minerals_high: int = 0

var combo_count: int = 0
var combo_timer: float = 0.0
var combo_timeout: float = 3.0
var combo_multiplier: float = 1.0

var enemy_rewards: Dictionary = {
	"melee": {"coin": 10, "mineral_low": 2, "mineral_mid": 0, "mineral_high": 0},
	"sentry": {"coin": 14, "mineral_low": 3, "mineral_mid": 0, "mineral_high": 0},
	"raven": {"coin": 18, "mineral_low": 4, "mineral_mid": 0, "mineral_high": 0},
	"boss": {"coin": 250, "mineral_low": 0, "mineral_mid": 40, "mineral_high": 0},
}

var is_game_over: bool = false
var is_paused: bool = false
var is_upgrading: bool = false

var time_remaining: float = 0.0
var has_timer: bool = false
var timer_counting_up: bool = false  # true = counting elapsed time (repeat runs), false = countdown (first clear)
var timer_elapsed: float = 0.0       # accumulated elapsed time for counting-up mode
var boss_killed_in_run: bool = false  # whether at least one special boss was killed this run
const FIRST_RUN_DURATION: float = 300.0

var shield_regen_timer: float = 0.0
var lifesteal_timer: float = 0.0

var upgrade_counts: Dictionary = {}
var upgrade_pool: Array = []

var current_stage: StageData.StageInfo
var current_chapter_id: int = 1
var boss_remaining: int = 0
var is_boss_phase: bool = false
var boss_active_count: int = 0
var boss_respawn_timer: float = 0.0
var boss_respawn_delay: float = 5.0
var is_boss_infinite: bool = false
var _timer_expired_once: bool = false

var session_loot: Array = []

const DROP_WEAPONS: Array[int] = [
	WeaponData.WeaponID.SMALL_MISSILE,
	WeaponData.WeaponID.SMALL_CANNON,
	WeaponData.WeaponID.SMALL_RAILGUN,
	WeaponData.WeaponID.SMALL_LASER,
]

const DROP_ARMOR: Array[int] = [0, 1]

func try_drop_equipment(enemy_pos: Vector2) -> void:
	if randf() > 0.005:
		return
	var loot_type := "weapon" if randf() < 0.7 else "armor"
	var loot: Dictionary = {}
	if loot_type == "weapon":
		var wid := DROP_WEAPONS[randi() % DROP_WEAPONS.size()]
		var shop_item_id_map: Dictionary = {
			WeaponData.WeaponID.SMALL_MISSILE: ShopItemData.ShopItemID.SMALL_MISSILE,
			WeaponData.WeaponID.SMALL_CANNON: ShopItemData.ShopItemID.SMALL_CANNON,
			WeaponData.WeaponID.SMALL_RAILGUN: ShopItemData.ShopItemID.SMALL_RAILGUN,
			WeaponData.WeaponID.SMALL_LASER: ShopItemData.ShopItemID.SMALL_LASER,
		}
		var sid = shop_item_id_map.get(wid, ShopItemData.ShopItemID.SMALL_MISSILE)
		var shop_item = ShopItemData.get_item(sid)
		loot = {
			"type": "weapon",
			"shop_item_id": sid,
			"scene_path": shop_item.scene_path,
			"quality": EquipmentData.Quality.COMMON,
			"name": shop_item.display_name,
			"equip_id": str(randi()),
			"equip_type": "WEAPON",
			"base_damage": shop_item.base_damage,
			"fire_interval": shop_item.fire_interval,
			"range": shop_item.range,
			"crit_rate": shop_item.crit_rate,
			"crit_mult": shop_item.crit_mult,
			"tonnage_tier": shop_item.tonnage_tier,
			"star_coin_price": shop_item.star_coin_price,
			"pos": enemy_pos
		}
	else:
		var aid := DROP_ARMOR[randi() % DROP_ARMOR.size()]
		var armor_bonus = EquipmentData.get_armor_bonus(aid)
		loot = {
			"type": "armor",
			"armor_id": aid,
			"quality": EquipmentData.Quality.COMMON,
			"name": EquipmentData.get_armor_name(aid),
			"equip_id": str(randi()),
			"equip_type": "ARMOR",
			"shield_bonus": armor_bonus.get("shield_bonus", 0.0),
			"shield_regen_bonus": armor_bonus.get("shield_regen_bonus", 0.0),
			"pos": enemy_pos
		}
	add_loot(loot)
	_spawn_loot_effect(enemy_pos, loot_type, loot)

func spawn_boss_loot(enemy_pos: Vector2) -> void:
	if randf() > 1.0:
		return
	var loot_type := "weapon" if randf() < 0.7 else "armor"
	var loot: Dictionary = {}
	if loot_type == "weapon":
		var wid := DROP_WEAPONS[randi() % DROP_WEAPONS.size()]
		var shop_item_id_map: Dictionary = {
			WeaponData.WeaponID.SMALL_MISSILE: ShopItemData.ShopItemID.SMALL_MISSILE,
			WeaponData.WeaponID.SMALL_CANNON: ShopItemData.ShopItemID.SMALL_CANNON,
			WeaponData.WeaponID.SMALL_RAILGUN: ShopItemData.ShopItemID.SMALL_RAILGUN,
			WeaponData.WeaponID.SMALL_LASER: ShopItemData.ShopItemID.SMALL_LASER,
		}
		var sid = shop_item_id_map.get(wid, ShopItemData.ShopItemID.SMALL_MISSILE)
		var shop_item = ShopItemData.get_item(sid)
		loot = {
			"type": "weapon",
			"shop_item_id": sid,
			"scene_path": shop_item.scene_path,
			"quality": EquipmentData.Quality.COMMON,
			"name": shop_item.display_name,
			"equip_id": str(randi()),
			"equip_type": "WEAPON",
			"base_damage": shop_item.base_damage,
			"fire_interval": shop_item.fire_interval,
			"range": shop_item.range,
			"crit_rate": shop_item.crit_rate,
			"crit_mult": shop_item.crit_mult,
			"tonnage_tier": shop_item.tonnage_tier,
			"star_coin_price": shop_item.star_coin_price,
			"pos": enemy_pos
		}
	else:
		var aid := DROP_ARMOR[randi() % DROP_ARMOR.size()]
		var armor_bonus = EquipmentData.get_armor_bonus(aid)
		loot = {
			"type": "armor",
			"armor_id": aid,
			"quality": EquipmentData.Quality.COMMON,
			"name": EquipmentData.get_armor_name(aid),
			"equip_id": str(randi()),
			"equip_type": "ARMOR",
			"shield_bonus": armor_bonus.get("shield_bonus", 0.0),
			"shield_regen_bonus": armor_bonus.get("shield_regen_bonus", 0.0),
			"pos": enemy_pos
		}
	add_loot(loot)
	_spawn_loot_effect(enemy_pos, loot_type, loot)

func _spawn_loot_effect(world_pos: Vector2, loot_type: String, loot: Dictionary) -> void:
	if not damage_root or not is_instance_valid(damage_root):
		return
	var item_name = loot.get("name", "武器" if loot_type == "weapon" else "防具")
	var label := Label.new()
	label.text = "[%s]" % item_name
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	label.position = world_pos + Vector2(randf_range(-30, 30), -40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_root.call_deferred("add_child", label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 60, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)

func _ready() -> void:
	_setup_upgrade_pool()
	_setup_references()
	_spawn_player()

func _setup_upgrade_pool() -> void:
	upgrade_pool = [
		{"id": "damage", "name": "伤害强化", "desc": "所有武器伤害 x1.2", "max": 3, "weight": "high"},
		{"id": "shield_max", "name": "临时护盾", "desc": "shield_max +30，立即补满", "max": 3, "weight": "mid"},
		{"id": "shield_regen", "name": "护盾充能", "desc": "shield_regen x1.5", "max": 3, "weight": "mid"},
		{"id": "fire_coverage", "name": "火力覆盖", "desc": "导弹哒哒哒连射（Lv.1=2发/Lv.2=3发/Lv.3=4发）", "max": 3, "weight": "high"},
		{"id": "silent_hunter", "name": "静默猎手", "desc": "静止时射速+15%（fire_interval x0.85）", "max": 3, "weight": "low"},
		{"id": "precision_kill", "name": "精准猎杀", "desc": "导弹索敌范围 +100", "max": 3, "weight": "low"},
		{"id": "cannon_bloodthirst", "name": "嗜血残暴", "desc": "单次加农炮子弹数量 +1", "max": 3, "weight": "mid"},
		{"id": "cannon_rush", "name": "狂飙突进", "desc": "移动时射速 +15%", "max": 3, "weight": "low"},
		{"id": "cannon_vengeance", "name": "为了部落", "desc": "受伤时射速 +15%，持续2秒", "max": 3, "weight": "low"},
		{"id": "railgun_damage", "name": "一发入魂", "desc": "磁轨炮伤害 +20%", "max": 3, "weight": "low"},
		{"id": "railgun_crit", "name": "命中注定", "desc": "磁轨炮暴击率 +10%", "max": 3, "weight": "low"},
		{"id": "railgun_multi", "name": "多重射击", "desc": "单次射击次数 +1", "max": 3, "weight": "low"},
		{"id": "laser_pierce", "name": "高效光束", "desc": "激光宽度 +20%", "max": 3, "weight": "mid"},
		{"id": "laser_overload", "name": "能量过载", "desc": "激光持续时间 +20%", "max": 3, "weight": "mid"},
		{"id": "laser_shield_penetration", "name": "护盾穿透", "desc": "对护盾伤害每级 +20%", "max": 3, "weight": "low"},
	]

func setup_for_stage(chapter_id: int, stage_id: int) -> void:
	current_chapter_id = chapter_id
	current_stage = StageData.get_stage(chapter_id, stage_id)
	if current_stage == null:
		push_warning("[GameManager] Stage not found, using defaults")
		current_stage = StageData.get_stage(1, 1)

	boss_remaining = current_stage.boss_count if current_stage else 1
	is_boss_phase = current_stage.type == StageData.StageType.BOSS_ONLY
	is_boss_infinite = false
	_timer_expired_once = false
	boss_respawn_timer = 0.0

	var stats := StageData.calc_enemy_stats(
		30.0, 10.0, 100.0, 2.0,
		current_stage, player_level
	)
	enemy_hp = stats["hp"]
	enemy_damage = stats["damage"]
	enemy_move_speed = stats["speed"]
	spawn_interval = stats["spawn_interval"]

	if current_stage.has_timer:
		# 首次通关(撑过5分钟+击杀BOSS)之前: 倒计时模式
		# 首次通关之后再次进入: 向上增量计时模式
		if GameState.is_stage_first_complete(GameState.selected_stage_id):
			has_timer = true
			timer_counting_up = true
			timer_elapsed = 0.0
			time_remaining = 0.0
		else:
			has_timer = true
			timer_counting_up = false
			time_remaining = FIRST_RUN_DURATION
			timer_elapsed = 0.0
		is_boss_infinite = false
	else:
		has_timer = false
		timer_counting_up = false
		time_remaining = 0.0
		timer_elapsed = 0.0
		is_boss_infinite = false

	boss_killed_in_run = false

	session_loot = []
	_debug("setup_for_stage: chapter=%d stage=%d strength=%s interval=%.2f" % [
		chapter_id, stage_id, stats["hp"], spawn_interval])

func _setup_references() -> void:
	var game_scene = get_parent()
	enemy_root = game_scene.get_node_or_null("EnemyRoot")
	bullet_root = game_scene.get_node_or_null("BulletRoot")
	exp_orb_root = game_scene.get_node_or_null("ExpOrbRoot")
	damage_root = game_scene.get_node_or_null("DamageRoot")
	effect_root = game_scene.get_node_or_null("EffectRoot")
	effect_manager = game_scene.get_node_or_null("EffectRoot/WeaponEffectManager")
	boss_warning = game_scene.get_node_or_null("UIRoot/BossWarning")

func _apply_race_to_gm(race: RaceData) -> void:
	var ship = ShipData.get_ship(GameState.selected_ship_id)
	var ship_base_hp = ship.base_hp if ship else 100
	var ship_base_shield = ship.base_shield if ship else 50
	player_hp = ship_base_hp
	player_max_hp = ship_base_hp
	player_shield_max = ship_base_shield
	player_shield = ship_base_shield
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
	laser_width = 16.0
	laser_duration = 2.0
	laser_shield_penetration_mult = 1.0

	for talent in race.talents:
		match talent.get("type"):
			"cannon_fire_rate":
				race_talent_counts["cannon_fire_rate"] = int(talent.get("value", 1))
				cannon_fire_interval *= (1.0 - talent.get("value", 0.0))
			"cannon_base_level":
				race_talent_counts["cannon_bloodthirst"] = int(talent.get("value", 1))
				race_talent_counts["cannon_rush"] = int(talent.get("value", 1))
				race_talent_counts["cannon_vengeance"] = int(talent.get("value", 1))
				for i in range(int(talent.get("value", 1))):
					_apply_upgrade_effect("cannon_bloodthirst")
					_apply_upgrade_effect("cannon_rush")
					_apply_upgrade_effect("cannon_vengeance")
			"missile_range":
				race_talent_counts["missile_range"] = int(talent.get("value", 1))
				missile_range *= (1.0 + talent.get("value", 0.0))
			"missile_base_level":
				race_talent_counts["fire_coverage"] = int(talent.get("value", 1))
				race_talent_counts["silent_hunter"] = int(talent.get("value", 1))
				race_talent_counts["precision_kill"] = int(talent.get("value", 1))
				for i in range(int(talent.get("value", 1))):
					_apply_upgrade_effect("fire_coverage")
					_apply_upgrade_effect("silent_hunter")
					_apply_upgrade_effect("precision_kill")
			"railgun_base_level":
				race_talent_counts["railgun_damage"] = int(talent.get("value", 1))
				race_talent_counts["railgun_crit"] = int(talent.get("value", 1))
				race_talent_counts["railgun_multi"] = int(talent.get("value", 1))
				for i in range(int(talent.get("value", 1))):
					_apply_upgrade_effect("railgun_damage")
					_apply_upgrade_effect("railgun_crit")
					_apply_upgrade_effect("railgun_multi")
			"laser_base_level":
				for i in range(int(talent.get("value", 1))):
					laser_width *= 1.2
					laser_duration *= 1.2
					laser_shield_penetration_mult *= pow(1.2, int(talent.get("value", 1)))
				race_talent_counts["laser_pierce"] = int(talent.get("value", 1))
				race_talent_counts["laser_overload"] = int(talent.get("value", 1))
				race_talent_counts["laser_shield_penetration"] = int(talent.get("value", 1))
			"railgun_crit":
				race_talent_counts["railgun_crit"] = int(talent.get("value", 1))
				railgun_crit_bonus += talent.get("value", 0.0)
			_:
				pass
	_apply_armor_bonuses_to_gm()

func _apply_armor_bonuses_to_gm() -> void:
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE
	var armor_list: Array = GameState.equipped_armor.get(ship_id, [])
	if not (armor_list is Array):
		armor_list = []
	for armor_item in armor_list:
		if armor_item is Dictionary and not armor_item.is_empty():
			player_shield_max += armor_item.get("shield_bonus", 0.0)
			player_shield_regen += armor_item.get("shield_regen_bonus", 0.0)
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
		"fire_coverage":
			spread_count += 1
		"silent_hunter":
			silent_hunter_level = upgrade_counts.get("silent_hunter", 0)
		"precision_kill":
			missile_range += 100.0
		"laser_pierce":
			laser_width *= 1.2
		"laser_overload":
			laser_duration *= 1.2
		"laser_shield_penetration":
			laser_shield_penetration_mult *= 1.2

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
		if player.has_method("sync_from_game_manager"):
			player.sync_from_game_manager(self)
	else:
		push_error("[GameManager] failed to load Player scene")

func start_run_timer() -> void:
	if current_stage != null and current_stage.has_timer:
		has_timer = true
		if not timer_counting_up:
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
	_update_boss_respawn(delta)
	_update_shield_regen(delta)
	_update_lifesteal(delta)
	_update_combo(delta)
	_check_boss_warning()

func _update_timer(delta: float) -> void:
	if not has_timer:
		return
	if timer_counting_up:
		timer_elapsed += delta
		time_remaining = timer_elapsed
		_notify_hud_update()
	else:
		if time_remaining <= 0.0:
			return
		time_remaining -= delta
		if time_remaining <= 0.0:
			time_remaining = 0.0
			_notify_hud_update()
			print("[GM] _update_timer: time_remaining reached 0! Calling _on_timer_expired")
			_on_timer_expired()
		elif time_remaining < 5.0 and time_remaining > 0.0:
			print("[GM] _update_timer: time_remaining=", time_remaining)

func _on_timer_expired() -> void:
	print("[GM] _on_timer_expired called, is_boss_phase=", is_boss_phase, " _timer_expired_once=", _timer_expired_once)
	if is_boss_phase and not _timer_expired_once:
		_timer_expired_once = true
		is_boss_infinite = true
		is_game_over = false
		get_tree().paused = false
		has_timer = false
		time_remaining = 0.0
		_notify_hud_update()
		return
	is_game_over = true
	get_tree().paused = true
	# 注意：on_stage_complete 在 game_ended 信号处理函数 _on_game_ended
	# 中通过 _show_settlement_screen 内部调用，此处不再重复调用
	game_ended.emit("timeout")

func _update_boss_respawn(delta: float) -> void:
	if not is_boss_phase:
		return
	if is_boss_infinite:
		boss_respawn_timer += delta
		if boss_respawn_timer >= boss_respawn_delay:
			boss_respawn_timer = 0.0
			_spawn_single_boss()

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

	if boss_active_count > 0:
		if randf() < 0.5:
			return

	if is_boss_phase:
		return

	var enemy_path := _choose_enemy_type()
	if enemy_path == "":
		return
	if not ResourceLoader.exists(enemy_path):
		push_error("[GameManager] Enemy scene not found: " + enemy_path)
		return

	var enemy_scene = load(enemy_path)
	var enemy = enemy_scene.instantiate()
	enemy_root.add_child(enemy)

	var spawn_distance := randf_range(600.0, 900.0)
	var spawn_angle := randf_range(0, TAU)
	enemy.global_position = player.global_position + Vector2.from_angle(spawn_angle) * spawn_distance

	match enemy_path:
		ENEMY_MELEE_PATH:
			var base_shield := 10.0
			var base_regen := 1.0
			var scale := enemy_hp / 30.0
			enemy.setup_enemy(self, enemy_hp, enemy_damage, enemy_move_speed, base_shield * scale, base_regen * scale, current_stage.id if current_stage else 1)
			enemy.enemy_dead.connect(_on_enemy_dead)
		ENEMY_SENTRY_PATH:
			var base_shield := 7.0
			var base_regen := 0.7
			var scale := (enemy_hp * 0.7) / 30.0
			enemy.setup_enemy(self, enemy_hp * 0.7, enemy_damage * 0.8, 60.0, base_shield * scale, base_regen * scale, current_stage.id if current_stage else 1)
			enemy.enemy_dead.connect(_on_enemy_dead)
		ENEMY_RAVEN_PATH:
			var base_shield := 5.0
			var base_regen := 0.5
			var scale := (enemy_hp * 0.5) / 30.0
			enemy.setup_enemy(self, enemy_hp * 0.5, enemy_damage * 1.5, 200.0, base_shield * scale, base_regen * scale, current_stage.id if current_stage else 1)
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
	if boss_active_count > 0:
		return
	if is_boss_phase:
		if is_boss_infinite:
			if boss_active_count < 5:
				_spawn_single_boss()
		else:
			for _i in range(mini(5, boss_remaining)):
				_spawn_single_boss()
		return
	if kill_since_boss >= 45 and kill_since_boss < 50:
		if boss_warning and boss_warning.has_method("show_warning"):
			boss_warning.show_warning()
	elif kill_since_boss >= 50:
		_spawn_single_boss()

func _spawn_single_boss() -> void:
	if not ResourceLoader.exists(BOSS_SCENE_PATH):
		push_error("[GameManager] BossVoid.tscn NOT FOUND!")
		return
	if not player or not is_instance_valid(player):
		return

	boss_active_count += 1

	if boss_active_count == 1:
		SoundManager.play_sfx("boss_appear")
		SoundManager.play_music("battle_boss")
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
	boss_active_count = maxi(0, boss_active_count - 1)
	kill_since_boss = 0
	boss_killed_in_run = true

	if boss_active_count == 0:
		SoundManager.play_music("battle")
		if boss_warning and boss_warning.has_method("hide_warning"):
			boss_warning.hide_warning()

	var reward = enemy_rewards.get("boss", {"coin": 250, "mineral_low": 0, "mineral_mid": 40, "mineral_high": 0})
	var reward_coin = int(reward["coin"])
	var reward_mineral_low = int(reward.get("mineral_low", 0))
	var reward_mineral_mid = int(reward.get("mineral_mid", 0))
	var reward_mineral_high = int(reward.get("mineral_high", 0))
	session_star_coin += reward_coin
	session_minerals_low += reward_mineral_low
	session_minerals_mid += reward_mineral_mid
	session_minerals_high += reward_mineral_high

	if is_boss_phase and not is_boss_infinite:
		boss_remaining -= 1
		if boss_remaining <= 0:
			is_game_over = true
			get_tree().paused = true
			# 触发 game_ended 信号，由 _on_game_ended → _show_settlement_screen 处理
			# 注意：不在此处调用 on_stage_complete()，由 _show_settlement_screen 内部调用
			game_ended.emit("timeout")
	_notify_hud_update()

func on_stage_complete() -> void:
	if current_stage == null:
		return
	session_star_coin += current_stage.stage_complete_star_coin

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
	var reward_mineral_low = int(reward.get("mineral_low", 0) * combo_multiplier)
	var reward_mineral_mid = int(reward.get("mineral_mid", 0) * combo_multiplier)
	var reward_mineral_high = int(reward.get("mineral_high", 0) * combo_multiplier)
	session_star_coin += reward_coin
	session_minerals_low += reward_mineral_low
	session_minerals_mid += reward_mineral_mid
	session_minerals_high += reward_mineral_high

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
	enemy_hp *= 1.20
	enemy_damage *= 1.15
	enemy_move_speed *= 1.025
	spawn_interval = maxf(0.1, spawn_interval - 0.15)

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
	var research_bonus = GameState.research_progress.get(upgrade_id, 0)
	var effective_max = data["max"] + research_bonus
	if upgrade_counts[upgrade_id] >= effective_max:
		_debug("upgrade max reached!")
		is_upgrading = false
		get_tree().paused = false
		return

	var is_first_pick = upgrade_counts[upgrade_id] == 0
	upgrade_counts[upgrade_id] += 1

	match upgrade_id:
		"damage":
			player_damage *= 1.2 * _research_mult(upgrade_id)
		"shield_max":
			player_shield_max += 30.0
			player_shield = player_shield_max
		"fire_coverage":
			if is_first_pick:
				spread_count += research_bonus
			spread_count += 1
		"shield_regen":
			player_shield_regen *= 1.5 * _research_mult(upgrade_id)
		"silent_hunter":
			silent_hunter_level = upgrade_counts["silent_hunter"]
		"precision_kill":
			if is_first_pick:
				missile_range += 100.0 * research_bonus
			missile_range += 100.0
		"cannon_bloodthirst":
			if is_first_pick:
				cannon_bloodthirst += research_bonus
			cannon_bloodthirst += 1
		"cannon_rush":
			cannon_rush_level = upgrade_counts["cannon_rush"]
			cannon_fire_interval *= pow(0.85, upgrade_counts["cannon_rush"])
		"cannon_vengeance":
			cannon_vengeance_level = upgrade_counts["cannon_vengeance"]
		"railgun_damage":
			railgun_damage *= 1.2 * _research_mult(upgrade_id)
		"railgun_crit":
			railgun_crit_bonus += 0.1 * _research_mult(upgrade_id)
		"railgun_multi":
			if is_first_pick:
				railgun_multi_count += research_bonus
			railgun_multi_count += 1
		"laser_pierce":
			if is_first_pick:
				laser_width *= pow(1.2, research_bonus)
			laser_width *= 1.2
		"laser_overload":
			if is_first_pick:
				laser_duration *= pow(1.2, research_bonus)
			laser_duration *= 1.2
		"laser_shield_penetration":
			if is_first_pick:
				laser_shield_penetration_mult *= pow(1.2, research_bonus)
			laser_shield_penetration_mult *= 1.2

	if player and is_instance_valid(player) and player.has_method("sync_from_game_manager"):
		player.sync_from_game_manager(self)

	if player and is_instance_valid(player) and player.has_method("sync_from_game_manager"):
		player.sync_from_game_manager(self)

	is_upgrading = false
	get_tree().paused = false
	_notify_hud_update()

func _apply_research_bonuses() -> void:
	for upgrade_id in GameState.research_progress.keys():
		var level = GameState.research_progress[upgrade_id]
		if level <= 0:
			continue
		match upgrade_id:
			"fire_coverage":
				spread_count += level
			"silent_hunter":
				silent_hunter_level = level
			"precision_kill":
				missile_range += 100.0 * float(level)
			"cannon_bloodthirst":
				cannon_bloodthirst += level
			"cannon_rush":
				cannon_rush_level = level
				cannon_fire_interval *= pow(0.85, float(level))
			"cannon_vengeance":
				cannon_vengeance_level = level
			"railgun_damage":
				railgun_damage *= pow(1.2, float(level))
			"railgun_crit":
				railgun_crit_bonus += 0.1 * float(level)
			"railgun_multi":
				railgun_multi_count += level
			"laser_pierce":
				laser_width *= pow(1.2, float(level))
			"laser_overload":
				laser_duration *= pow(1.2, float(level))
			"laser_shield_penetration":
				laser_shield_penetration_mult *= pow(1.2, float(level))
	if player and is_instance_valid(player) and player.has_method("sync_from_game_manager"):
		player.sync_from_game_manager(self)

func _research_mult(upgrade_id: String) -> float:
	return 1.0 + 0.25 * float(GameState.research_progress.get(upgrade_id, 0))

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

func add_loot(loot_data: Dictionary) -> void:
	session_loot.append(loot_data)
	_debug("add_loot: " + str(loot_data) + " total: " + str(session_loot.size()))

func get_session_loot() -> Array:
	return session_loot

func grant_loot_to_player() -> void:
	for loot: Dictionary in session_loot:
		var 		item_dict := {
			"type": loot.get("type", "weapon"),
			"shop_item_id": loot.get("shop_item_id", 0),
			"weapon_id": loot.get("weapon_id", 0),
			"armor_id": loot.get("armor_id", 0),
			"quality": loot.get("quality", 0),
			"is_new": true,
			"name": loot.get("name", ""),
			"scene_path": loot.get("scene_path", ""),
			"base_damage": loot.get("base_damage", 0.0),
			"fire_interval": loot.get("fire_interval", 0.0),
			"range": loot.get("range", 0.0),
			"crit_rate": loot.get("crit_rate", 0.0),
			"crit_mult": loot.get("crit_mult", 0.0),
			"tonnage_tier": loot.get("tonnage_tier", 0),
			"star_coin_price": loot.get("star_coin_price", 0),
			"shield_bonus": loot.get("shield_bonus", 0.0),
			"shield_regen_bonus": loot.get("shield_regen_bonus", 0.0),
			"equip_type": loot.get("equip_type", "WEAPON"),
			"equip_id": loot.get("equip_id", str(randi())),
		}
		GameState.equipment_inventory.append(item_dict)
	_debug("grant_loot: granted " + str(session_loot.size()) + " items to player inventory")
	session_loot.clear()

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
	boss_active_count = 0
	boss_respawn_timer = 0.0
	boss_remaining = current_stage.boss_count if current_stage else 1
	is_boss_phase = current_stage.type == StageData.StageType.BOSS_ONLY if current_stage else false
	is_boss_infinite = false
	_timer_expired_once = false
	enemy_hp = 30.0
	enemy_damage = 10.0
	enemy_move_speed = 100.0
	spawn_interval = 2.0
	spawn_timer = 0.0
	player_hp = 100
	player_max_hp = 100
	var rs = ShipData.get_ship(GameState.selected_ship_id)
	var rs_shield = rs.base_shield if rs else 50
	player_shield = rs_shield
	player_shield_max = rs_shield
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
	laser_width = 16.0
	laser_duration = 2.0
	laser_shield_penetration_mult = 1.0
	current_xp = 0.0
	xp_to_next_level = 10.0
	player_level = 1
	session_star_coin = 0
	session_minerals_low = 0
	session_minerals_mid = 0
	session_minerals_high = 0
	shield_regen_timer = 0.0
	lifesteal_timer = 0.0
	upgrade_counts = {}
	race_talent_counts = {}
	upgrade_pool = []
	_setup_upgrade_pool()
	_apply_research_bonuses()

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

func spawn_weapon_effect(effect_name: String, position: Vector2, direction: Vector2, params: Dictionary = {}) -> Node2D:
	if not effect_manager or not is_instance_valid(effect_manager):
		return null
	if effect_manager.has_method("spawn_effect"):
		return effect_manager.spawn_effect(effect_name, position, direction, params)
	return null

func spawn_laser_charge(position: Vector2, direction: Vector2) -> Node2D:
	return spawn_weapon_effect("laser_charge", position, direction)

func spawn_laser_beam_vfx(position: Vector2, direction: Vector2, params: Dictionary = {}) -> Node2D:
	return spawn_weapon_effect("laser_beam_vfx", position, direction, params)

func spawn_railgun_charge(position: Vector2, direction: Vector2) -> Node2D:
	return spawn_weapon_effect("railgun_charge", position, direction)

func spawn_railgun_projectile_vfx(position: Vector2, direction: Vector2, params: Dictionary = {}) -> Node2D:
	return spawn_weapon_effect("railgun_projectile", position, direction, params)

func spawn_cannon_muzzle(position: Vector2, direction: Vector2) -> Node2D:
	return spawn_weapon_effect("cannon_muzzle", position, direction)

func spawn_cannon_smoke(position: Vector2, direction: Vector2) -> Node2D:
	return spawn_weapon_effect("cannon_smoke", position, direction)

func spawn_missile_launch(position: Vector2, direction: Vector2) -> Node2D:
	return spawn_weapon_effect("missile_launch", position, direction)

func spawn_missile_trail(position: Vector2, direction: Vector2, params: Dictionary = {}) -> Node2D:
	return spawn_weapon_effect("missile_trail", position, direction, params)

func spawn_missile_explosion(position: Vector2, params: Dictionary = {}) -> Node2D:
	return spawn_weapon_effect("missile_explosion", position, Vector2.RIGHT, params)

func clear_all_effects() -> void:
	if effect_manager and effect_manager.has_method("clear_all_effects"):
		effect_manager.clear_all_effects()
