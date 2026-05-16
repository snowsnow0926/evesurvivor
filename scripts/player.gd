extends CharacterBody2D

const DEBUG := false

func _debug(msg: String) -> void:
	if DEBUG:
		print("[Player] ", msg)

const RaceData = preload("res://resources/race_data.gd")
const ShipData = preload("res://resources/ship_data.gd")
const WeaponData = preload("res://resources/weapon_data.gd")
const ShipIconGenerator = preload("res://scripts/ship_icon_generator.gd")
const PlayerStats = preload("res://resources/player_stats.gd")
const EquipmentData = preload("res://resources/equipment_data.gd")

const _SCENE_MISSILE: PackedScene = preload("res://scenes/Missile.tscn")
const _SCENE_CANNON: PackedScene = preload("res://scenes/CannonBullet.tscn")
const _SCENE_RAILGUN: PackedScene = preload("res://scenes/RailgunBullet.tscn")
const _SCENE_LASER: PackedScene = preload("res://scenes/LaserBeam.tscn")

const _RACE_ICON_MAP: Dictionary = {
	RaceData.RaceID.HUMAN:   "player_human",
	RaceData.RaceID.ORC:     "player_orc",
	RaceData.RaceID.PLANT:   "player_plant",
	RaceData.RaceID.SILICON: "player_silicon",
	RaceData.RaceID.DIVINE:  "player_human",
}

var game_manager: Node2D
var player_stats: PlayerStats

var race_talents: Array = []
var default_weapon_scene: String = "res://scenes/Missile.tscn"

var active_weapons: Array = []
var weapon_fire_timers: Dictionary = {}
var weapon_fire_ready: Dictionary = {}

var missile_burst_timers: Dictionary = {}
var missile_burst_counts: Dictionary = {}
const MISSILE_BURST_INTERVAL: float = 0.1

var railgun_burst_count: int = 0
var railgun_burst_timer: float = 0.0
const RAILGUN_BURST_INTERVAL: float = 0.1

var _is_moving: bool = false
var _stationary_timer: float = 0.0
var _is_stationary: bool = false

var _physics_tick_counter: int = 0

var fire_timer: float = 0.0
var current_angle: float = 0.0
var target_angle: float = 0.0
var turn_time: float = 0.12

var polygon: Node2D
var ship_sprite: Sprite2D
var ship_exhaust: Node2D

const _SHIP_ICON_MAP: Dictionary = {
	ShipData.ShipID.FRIGATE:      "frigate",
	ShipData.ShipID.CRUISER:       "cruiser",
	ShipData.ShipID.BATTLECRUISER: "battlecruiser",
	ShipData.ShipID.BATTLESHIP:    "battleship",
	ShipData.ShipID.DREADNOUGHT:   "dreadnought",
	ShipData.ShipID.TITAN:         "titan",
}

func set_ship_icon() -> void:
	var sid = int(GameState.selected_ship_id)
	if sid == 0:
		sid = ShipData.ShipID.FRIGATE

	var icon_id: String = ""
	var race_id: int = GameState.selected_race_id as int
	var race_icon: String = _RACE_ICON_MAP.get(race_id, "")
	if not race_icon.is_empty():
		var race_entry: ShipIconGenerator.IconEntry = ShipIconGenerator.get_entry(ShipIconGenerator.Category.SHIP, race_icon)
		if race_entry != null and race_entry.get_texture() != null:
			icon_id = race_icon

	if icon_id.is_empty():
		icon_id = _SHIP_ICON_MAP.get(sid, "frigate")

	var entry: ShipIconGenerator.IconEntry = ShipIconGenerator.get_entry(ShipIconGenerator.Category.SHIP, icon_id)
	if entry == null:
		return
	var tex: Texture2D = entry.get_texture()
	if tex != null and ship_sprite != null:
		ship_sprite.texture = tex
		ship_sprite.scale = Vector2(0.3, 0.3)
		ship_sprite.visible = true
		if polygon != null:
			polygon.visible = false
	else:
		# fall back to polygon
		if entry.path.is_empty():
			return
		var polygon_points := ShipIconGenerator.build_polygon_from_path(entry.path)
		if polygon_points.is_empty():
			return
		if polygon != null:
			polygon.visible = false
		if ship_sprite != null:
			ship_sprite.visible = false
		queue_redraw()

func _ready() -> void:
	polygon = $Polygon2D
	ship_sprite = $ShipSprite
	ship_exhaust = $ShipExhaust
	_debug("_ready called, polygon=" + str(polygon) + ", sprite=" + str(ship_sprite))
	_debug("viewport size=" + str(get_viewport_rect().size))
	if polygon:
		polygon.rotation = -PI / 2
	_debug("polygon setup done")
	set_ship_icon()

const _SCENE_TO_BASE_WEAPON: Dictionary = {
	"res://scenes/Missile.tscn": WeaponData.WeaponID.MISSILE,
	"res://scenes/CannonBullet.tscn": WeaponData.WeaponID.CANNON,
	"res://scenes/RailgunBullet.tscn": WeaponData.WeaponID.RAILGUN,
	"res://scenes/LaserBeam.tscn": WeaponData.WeaponID.LASER,
}

## Sets weapon-related player_stats to their base defaults.
## Call once at game start after race/armor bonuses are applied.
func _init_weapon_defaults() -> void:
	player_stats.cannon_fire_interval = 1.2
	player_stats.cannon_pierce_count = 1
	player_stats.cannon_explode_chance = 0.0
	player_stats.cannon_bloodthirst = 0
	player_stats.railgun_damage = 30.0
	player_stats.railgun_speed = 1000.0
	player_stats.railgun_range = 400.0
	player_stats.railgun_fire_interval = 0.6
	player_stats.railgun_crit_bonus = 0.0
	player_stats.railgun_multi_count = 1
	player_stats.laser_damage = 12.0
	player_stats.laser_duration = 2.0
	player_stats.laser_width = 16.0
	player_stats.laser_fire_interval = 2.5
	player_stats.laser_shield_mult = 1.0

func _get_weapon_type_from_equipped(equipped_dict: Dictionary, scene_path: String) -> int:
	if equipped_dict.has("shop_item_id"):
		var sid = equipped_dict.get("shop_item_id")
		var shop_to_weapon_type: Dictionary = {
			0: WeaponData.WeaponID.SMALL_MISSILE,
			1: WeaponData.WeaponID.MEDIUM_MISSILE,
			2: WeaponData.WeaponID.LARGE_MISSILE,
			3: WeaponData.WeaponID.FLAGSHIP_MISSILE,
			4: WeaponData.WeaponID.SMALL_CANNON,
			5: WeaponData.WeaponID.MEDIUM_CANNON,
			6: WeaponData.WeaponID.LARGE_CANNON,
			7: WeaponData.WeaponID.FLAGSHIP_CANNON,
			8: WeaponData.WeaponID.SMALL_RAILGUN,
			9: WeaponData.WeaponID.MEDIUM_RAILGUN,
			10: WeaponData.WeaponID.LARGE_RAILGUN,
			11: WeaponData.WeaponID.FLAGSHIP_RAILGUN,
			12: WeaponData.WeaponID.SMALL_LASER,
			13: WeaponData.WeaponID.MEDIUM_LASER,
			14: WeaponData.WeaponID.LARGE_LASER,
			15: WeaponData.WeaponID.FLAGSHIP_LASER,
		}
		return shop_to_weapon_type.get(sid, _SCENE_TO_BASE_WEAPON.get(scene_path, WeaponData.WeaponID.MISSILE))
	return _SCENE_TO_BASE_WEAPON.get(scene_path, WeaponData.WeaponID.MISSILE)

func init_weapons() -> void:
	active_weapons.clear()
	weapon_fire_timers.clear()

	var sid = int(GameState.selected_ship_id)
	if sid == 0:
		sid = ShipData.ShipID.FRIGATE
	var equipped_list = GameState.equipped_weapons.get(sid)
	_debug("init_weapons: selected_ship_id=" + str(sid) + " equipped_list=" + str(equipped_list))
	var added_any = false

	if equipped_list is Array and not equipped_list.is_empty():
		for equipped_dict in equipped_list:
			if equipped_dict is Dictionary and equipped_dict.has("scene_path"):
				var scene_path = equipped_dict.get("scene_path", default_weapon_scene)
				var weapon_type = _get_weapon_type_from_equipped(equipped_dict, scene_path)
				var quality = equipped_dict.get("quality", 0)
				var weapon_data = WeaponData.get_weapon(weapon_type, quality)
				active_weapons.append(weapon_data)
				weapon_fire_timers[weapon_data.weapon_id] = 0.0
				weapon_fire_ready[weapon_data.weapon_id] = true
				added_any = true

	if not added_any:
		_debug("NO shop weapons found, using race default: " + default_weapon_scene)
		var weapon_type = _SCENE_TO_BASE_WEAPON.get(default_weapon_scene, WeaponData.WeaponID.MISSILE)
		var weapon_data = WeaponData.get_weapon(weapon_type)
		active_weapons.append(weapon_data)
		weapon_fire_timers[weapon_data.weapon_id] = 0.0
		weapon_fire_ready[weapon_data.weapon_id] = true
		_init_weapon_defaults()
	else:
		_debug("loaded " + str(active_weapons.size()) + " weapon(s) from shop")

func _physics_process(delta: float) -> void:
	_physics_tick_counter += 1
	if DEBUG and _physics_tick_counter % 60 == 0:
		print("[Player] _physics_process tick=", _physics_tick_counter, " active_weapons=", active_weapons.size(), " game_manager=", game_manager if game_manager else "NULL")
	if DEBUG and _physics_tick_counter % 120 == 0:
		_debug("alive tick=" + str(_physics_tick_counter) + _debug_player_state())
	if game_manager and game_manager.is_game_over:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if player_stats:
		player_stats.is_moving = _is_moving
		player_stats.is_stationary = _is_stationary
	_update_injured_state(delta)
	_update_movement(delta)
	_update_firing(delta)

func _debug_player_state() -> String:
	var bullet_root = game_manager.get("bullet_root") if game_manager else null
	var bullet_count = bullet_root.get_child_count() if bullet_root and is_instance_valid(bullet_root) else -1
	return " active_weapons=%d bullet_count=%d" % [active_weapons.size(), bullet_count]

func _get_mouse_world_pos() -> Vector2:
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_2d()
	if camera:
		return camera.get_global_mouse_position()
	return mouse_pos

func _update_injured_state(delta: float) -> void:
	if player_stats == null or not player_stats.is_injured:
		return
	player_stats.injured_timer -= delta
	if player_stats.injured_timer <= 0.0:
		player_stats.is_injured = false

func _update_movement(delta: float) -> void:
	var input_dir := Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	var mobile_input := MobileInput.joystick_output
	if mobile_input.length() > 0.05:
		input_dir = mobile_input

	if input_dir.length() > 0.05:
		input_dir = input_dir.normalized()
		target_angle = input_dir.angle()
		var angle_diff = target_angle - current_angle
		while angle_diff > PI:
			angle_diff -= 2 * PI
		while angle_diff < -PI:
			angle_diff += 2 * PI
		var t = clampf(delta / turn_time, 0.0, 1.0)
		current_angle += angle_diff * t
		_is_moving = true
		_stationary_timer = 0.0
		_is_stationary = false
	else:
		_is_moving = false
		_stationary_timer += delta
		if _stationary_timer >= 0.2 and velocity.length() < 5.0:
			_is_stationary = true
		else:
			_is_stationary = false

	velocity = input_dir * player_stats.move_speed
	move_and_slide()

	if ship_exhaust and ship_exhaust.has_method("update_exhaust"):
		ship_exhaust.update_exhaust(current_angle, velocity.length(), global_position)

	if ship_sprite and ship_sprite.visible:
		ship_sprite.rotation = current_angle + PI / 2
	elif polygon:
		polygon.rotation = current_angle + PI / 2
	if not ship_sprite or not ship_sprite.visible:
		queue_redraw()

func _update_firing(delta: float) -> void:
	if active_weapons.is_empty():
		return
	if DEBUG and _physics_tick_counter % 60 == 0:
		print("[Player] _update_firing: active_weapons=", active_weapons.map(func(w): return w.display_name))
	for weapon in active_weapons:
		var wt = weapon.weapon_id
		if not weapon_fire_timers.has(wt):
			weapon_fire_timers[wt] = 0.0
		if not weapon_fire_ready.has(wt):
			weapon_fire_ready[wt] = false
		if not weapon_fire_ready.get(wt, false):
			weapon_fire_timers[wt] += delta

		var missile_ids = [
			WeaponData.WeaponID.MISSILE, WeaponData.WeaponID.SMALL_MISSILE,
			WeaponData.WeaponID.MEDIUM_MISSILE, WeaponData.WeaponID.LARGE_MISSILE, WeaponData.WeaponID.FLAGSHIP_MISSILE
		]
		var railgun_ids = [
			WeaponData.WeaponID.RAILGUN, WeaponData.WeaponID.SMALL_RAILGUN,
			WeaponData.WeaponID.MEDIUM_RAILGUN, WeaponData.WeaponID.LARGE_RAILGUN, WeaponData.WeaponID.FLAGSHIP_RAILGUN
		]
		if wt in railgun_ids:
			_update_railgun_firing(delta, weapon)
		elif wt in missile_ids:
			_update_missile_firing(delta, weapon)
		else:
			var interval = _get_fire_interval(weapon)
			if DEBUG and _physics_tick_counter % 120 == 0:
				print("[Player] _update_firing: weapon=", weapon.display_name, " timer=", weapon_fire_timers[wt], " interval=", interval, " ready=", weapon_fire_ready.get(wt, false))
			if weapon_fire_ready.get(wt, false):
				_fire_weapon(weapon)
				weapon_fire_ready[wt] = false
				weapon_fire_timers[wt] = 0.0
			elif weapon_fire_timers[wt] >= interval:
				weapon_fire_ready[wt] = true
				weapon_fire_timers[wt] = 0.0
				_fire_weapon(weapon)
				weapon_fire_ready[wt] = false

func _get_fire_interval(weapon: WeaponData) -> float:
	var base = weapon.fire_interval
	var wt = weapon.weapon_id
	var missile_ids = [
		WeaponData.WeaponID.MISSILE, WeaponData.WeaponID.SMALL_MISSILE,
		WeaponData.WeaponID.MEDIUM_MISSILE, WeaponData.WeaponID.LARGE_MISSILE, WeaponData.WeaponID.FLAGSHIP_MISSILE
	]
	var cannon_ids = [
		WeaponData.WeaponID.CANNON, WeaponData.WeaponID.SMALL_CANNON,
		WeaponData.WeaponID.MEDIUM_CANNON, WeaponData.WeaponID.LARGE_CANNON, WeaponData.WeaponID.FLAGSHIP_CANNON
	]
	var railgun_ids = [
		WeaponData.WeaponID.RAILGUN, WeaponData.WeaponID.SMALL_RAILGUN,
		WeaponData.WeaponID.MEDIUM_RAILGUN, WeaponData.WeaponID.LARGE_RAILGUN, WeaponData.WeaponID.FLAGSHIP_RAILGUN
	]
	var laser_ids = [
		WeaponData.WeaponID.LASER, WeaponData.WeaponID.SMALL_LASER,
		WeaponData.WeaponID.MEDIUM_LASER, WeaponData.WeaponID.LARGE_LASER, WeaponData.WeaponID.FLAGSHIP_LASER
	]
	if wt in missile_ids:
		return player_stats.get_fire_interval_missile(base)
	elif wt in cannon_ids:
		return player_stats.get_fire_interval_cannon(weapon.fire_interval)
	elif wt in railgun_ids:
		return weapon.fire_interval
	elif wt in laser_ids:
		return weapon.fire_interval
	return base

func get_weapon_cd_remaining(weapon: WeaponData) -> float:
	var wt = weapon.weapon_id
	if weapon_fire_ready.get(wt, false):
		return -1.0
	var elapsed = weapon_fire_timers.get(wt, 0.0) as float
	var interval = _get_fire_interval(weapon)
	return interval - elapsed

func _update_railgun_firing(delta: float, weapon: WeaponData) -> void:
	var wt = weapon.weapon_id
	if railgun_burst_count > 0:
		railgun_burst_timer += delta
		if railgun_burst_timer >= RAILGUN_BURST_INTERVAL:
			railgun_burst_timer = 0.0
			railgun_burst_count -= 1
			var target_pos = _find_closest_enemy(weapon.range)
			if target_pos == Vector2.ZERO:
				return
			SoundManager.play_sfx("shoot_railgun")
			_fire_single_railgun(target_pos, weapon)
			if railgun_burst_count <= 0:
				weapon_fire_timers[wt] = 0.0
				weapon_fire_ready[wt] = false
	else:
		var interval = _get_fire_interval(weapon)
		if weapon_fire_ready.get(wt, false):
			var target_pos = _find_closest_enemy(weapon.range)
			if target_pos == Vector2.ZERO:
				return
			railgun_burst_count = player_stats.railgun_multi_count - 1
			railgun_burst_timer = 0.0
			SoundManager.play_sfx("shoot_railgun")
			_fire_single_railgun(target_pos, weapon)
			weapon_fire_ready[wt] = false
			weapon_fire_timers[wt] = 0.0
		elif weapon_fire_timers[wt] >= interval:
			weapon_fire_ready[wt] = true

func _fire_weapon(weapon: WeaponData) -> void:
	if not game_manager or not is_instance_valid(game_manager):
		return
	var enemy_root = game_manager.get("enemy_root")
	if not enemy_root or not is_instance_valid(enemy_root) or enemy_root.get_child_count() == 0:
		return

	var target_pos = _find_closest_enemy(weapon.range)
	if target_pos == Vector2.ZERO:
		target_pos = _get_mouse_world_pos()
	if weapon.weapon_id in [WeaponData.WeaponID.MISSILE, WeaponData.WeaponID.SMALL_MISSILE, WeaponData.WeaponID.MEDIUM_MISSILE, WeaponData.WeaponID.LARGE_MISSILE, WeaponData.WeaponID.FLAGSHIP_MISSILE]:
		_fire_missiles_at(target_pos, weapon)
	elif weapon.weapon_id in [WeaponData.WeaponID.CANNON, WeaponData.WeaponID.SMALL_CANNON, WeaponData.WeaponID.MEDIUM_CANNON, WeaponData.WeaponID.LARGE_CANNON, WeaponData.WeaponID.FLAGSHIP_CANNON]:
		_fire_cannon_at(target_pos, weapon)
	elif weapon.weapon_id in [WeaponData.WeaponID.RAILGUN, WeaponData.WeaponID.SMALL_RAILGUN, WeaponData.WeaponID.MEDIUM_RAILGUN, WeaponData.WeaponID.LARGE_RAILGUN, WeaponData.WeaponID.FLAGSHIP_RAILGUN]:
		_fire_railgun_at(target_pos, weapon)
	elif weapon.weapon_id in [WeaponData.WeaponID.LASER, WeaponData.WeaponID.SMALL_LASER, WeaponData.WeaponID.MEDIUM_LASER, WeaponData.WeaponID.LARGE_LASER, WeaponData.WeaponID.FLAGSHIP_LASER]:
		_fire_laser_at(weapon)

func _find_closest_enemy(max_range: float) -> Vector2:
	var enemy_root = game_manager.get("enemy_root")
	if not enemy_root:
		return Vector2.ZERO
	var count = enemy_root.get_child_count()
	if count == 0:
		return Vector2.ZERO
	var closest: Node2D = null
	var closest_dist = max_range
	for enemy in enemy_root.get_children():
		if not is_instance_valid(enemy) or not enemy is CharacterBody2D:
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy
	if closest:
		return closest.global_position
	return Vector2.ZERO

func _find_farthest_enemy_in_range(max_range: float) -> Node2D:
	var enemy_root = game_manager.get("enemy_root")
	if not enemy_root or not is_instance_valid(enemy_root):
		return null
	var farthest: Node2D = null
	var farthest_dist_sq: float = -1.0
	for enemy in enemy_root.get_children():
		if not is_instance_valid(enemy) or not enemy is CharacterBody2D:
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= max_range and dist * dist > farthest_dist_sq:
			farthest_dist_sq = dist * dist
			farthest = enemy
	return farthest

func _fire_missiles_at(target_pos: Vector2, weapon) -> void:
	_debug("firing missiles at " + str(target_pos))
	SoundManager.play_sfx("shoot_missile")
	if not game_manager:
		return
	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return

	_spawn_single_missile(target_pos, bullet_root, weapon)

	var total = player_stats.spread_count
	var burst_key = WeaponData.WeaponID.MISSILE
	if weapon and weapon.weapon_id == WeaponData.WeaponID.SMALL_MISSILE:
		burst_key = WeaponData.WeaponID.SMALL_MISSILE
	missile_burst_counts[burst_key] = total - 1
	missile_burst_timers[burst_key] = 0.0

func _update_missile_firing(delta: float, weapon) -> void:
	var wt = weapon.weapon_id
	if missile_burst_counts.get(wt, 0) > 0:
		if not missile_burst_timers.has(wt):
			missile_burst_timers[wt] = 0.0
		missile_burst_timers[wt] += delta
		if missile_burst_timers[wt] >= MISSILE_BURST_INTERVAL:
			missile_burst_timers[wt] = 0.0
			missile_burst_counts[wt] -= 1
			_fire_single_missile_for_burst(weapon)
			if missile_burst_counts[wt] <= 0:
				weapon_fire_timers[wt] = 0.0
				weapon_fire_ready[wt] = false
		return

	var interval = _get_fire_interval(weapon)
	if weapon_fire_ready.get(wt, false):
		var target_pos = _find_closest_enemy(weapon.range)
		if target_pos == Vector2.ZERO:
			return
		weapon_fire_ready[wt] = false
		_fire_missiles_at(target_pos, weapon)
	elif weapon_fire_timers[wt] >= interval:
		weapon_fire_ready[wt] = true

func _fire_single_missile_for_burst(weapon) -> void:
	var target_pos = _find_closest_enemy(weapon.range)
	if target_pos == Vector2.ZERO:
		target_pos = _get_mouse_world_pos()
	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return
	_spawn_single_missile(target_pos, bullet_root, weapon)

func _spawn_single_missile(target_pos: Vector2, bullet_root: Node, weapon: WeaponData) -> void:
	var base_angle = global_position.angle_to_point(target_pos)
	var missile = _SCENE_MISSILE.instantiate()
	bullet_root.add_child(missile)
	missile.global_position = global_position
	var quality_mult: float = EquipmentData.get_quality_mult(weapon.quality)
	var missile_damage: float = player_stats.damage * quality_mult
	missile.setup_target_direction(
		Vector2.from_angle(base_angle),
		missile_damage,
		player_stats.missile_speed,
		player_stats.crit_rate,
		player_stats.crit_mult,
		game_manager,
		player_stats.missile_splash_radius,
		player_stats.missile_splash_count,
		player_stats.missile_range,
		self
	)

func _fire_cannon_at(target_pos: Vector2, weapon: WeaponData) -> void:
	SoundManager.play_sfx("shoot_cannon")
	if not game_manager:
		return
	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return

	var dir = global_position.angle_to_point(target_pos)
	var bullet_count = 1 + player_stats.cannon_bloodthirst
	var spacing = 10.0
	var final_damage = weapon.damage
	var final_speed = weapon.projectile_speed
	var final_range = weapon.range

	for i in range(bullet_count):
		var offset_x = (i - (bullet_count - 1) * 0.5) * spacing
		var spawn_pos = global_position + Vector2.from_angle(dir).rotated(PI / 2) * offset_x

		var bullet = _SCENE_CANNON.instantiate()
		bullet_root.add_child(bullet)
		bullet.global_position = spawn_pos

		bullet.setup(
			Vector2.from_angle(dir),
			final_damage,
			final_speed,
			final_range,
			player_stats.crit_rate,
			player_stats.crit_mult,
			game_manager,
			player_stats.cannon_pierce_count,
			0.2,
			player_stats.cannon_explode_chance,
			80.0
		)

func _fire_railgun_at(target_pos: Vector2, weapon: WeaponData) -> void:
	SoundManager.play_sfx("shoot_railgun")
	if not game_manager:
		return
	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return

	_fire_single_railgun(target_pos, weapon)

func _fire_single_railgun(target_pos: Vector2, weapon: WeaponData) -> void:
	if not game_manager:
		return
	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return

	var base_angle = global_position.angle_to_point(target_pos)
	var count = player_stats.railgun_multi_count
	var spacing = 10.0
	var quality_mult: float = EquipmentData.get_quality_mult(weapon.quality)
	var railgun_damage: float = player_stats.railgun_damage * quality_mult

	for i in range(count):
		var offset_idx = i - (count - 1) * 0.5
		var final_angle = base_angle
		if count > 1:
			final_angle = base_angle + deg_to_rad(offset_idx * spacing)
		else:
			final_angle = base_angle

		var bullet = _SCENE_RAILGUN.instantiate()
		bullet_root.add_child(bullet)
		bullet.global_position = global_position

		var final_crit_rate = player_stats.crit_rate + player_stats.railgun_crit_bonus
		bullet.setup(
			Vector2.from_angle(final_angle),
			railgun_damage,
			player_stats.railgun_speed,
			player_stats.railgun_range,
			final_crit_rate,
			player_stats.crit_mult,
			game_manager
		)

func _fire_laser_at(weapon: WeaponData) -> void:
	var laser_target = _find_farthest_enemy_in_range(weapon.range)
	if laser_target == null:
		return
	SoundManager.play_sfx("shoot_laser")
	if not game_manager:
		return
	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return

	var laser = _SCENE_LASER.instantiate()
	bullet_root.add_child(laser)
	laser.global_position = global_position

	var dir = Vector2.RIGHT
	if laser_target != null:
		dir = (laser_target.global_position - global_position).normalized()

	laser.setup(
		dir,
		weapon.damage,
		weapon.duration,
		weapon.crit_rate,
		weapon.crit_mult,
		game_manager,
		weapon.beam_width,
		player_stats.laser_shield_mult,
		self,
		weapon.range
	)

func apply_race_data(race: RaceData) -> void:
	default_weapon_scene = race.base_weapon_scene
	race_talents = race.talents
	init_weapons()
	_apply_race_talents()
	_debug("Applied race data: " + race.display_name)
	set_ship_icon()

func _apply_race_talents() -> void:
	for talent in race_talents:
		match talent.get("type"):
			"cannon_fire_rate":
				player_stats.cannon_fire_interval *= (1.0 - talent.get("value", 0.0))
			"missile_range":
				player_stats.missile_range *= (1.0 + talent.get("value", 0.0))
			"railgun_crit":
				player_stats.railgun_crit_bonus += talent.get("value", 0.0)
			"laser_width_duration":
				player_stats.laser_width *= (1.0 + talent.get("value", 0.0))
				player_stats.laser_duration *= (1.0 + talent.get("value", 0.0))
			_:
				pass

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

func set_game_manager(gm: Node2D) -> void:
	game_manager = gm

func set_player_stats(ps: PlayerStats) -> void:
	player_stats = ps

func on_player_take_damage(amount: float) -> void:
	var final_amount = amount
	for talent in race_talents:
		if talent.get("type") == "damage_reduction":
			final_amount *= (1.0 - talent.get("value", 0.0))
	print("[玩家受伤] 原始伤害: %.1f → 最终伤害: %.1f" % [amount, final_amount])
	if game_manager and is_instance_valid(game_manager) and game_manager.has_method("on_player_take_damage"):
		game_manager.on_player_take_damage(final_amount)
	if player_stats:
		player_stats.is_injured = true
		player_stats.injured_timer = PlayerStats.INJURED_DURATION

func sync_from_player_stats(ps: PlayerStats) -> void:
	player_stats = ps

func get_primary_weapon() -> WeaponData:
	if not active_weapons.is_empty():
		return active_weapons[0]
	return null

func get_secondary_weapon() -> WeaponData:
	if active_weapons.size() > 1:
		return active_weapons[1]
	return null

func reset_state() -> void:
	pass

func _draw() -> void:
	if ship_sprite and ship_sprite.visible:
		return
	if polygon and polygon.visible:
		return
	var sid = int(GameState.selected_ship_id)
	if sid == 0:
		sid = ShipData.ShipID.FRIGATE
	var icon_id: String = _SHIP_ICON_MAP.get(sid, "frigate")
	var entry: ShipIconGenerator.IconEntry = ShipIconGenerator.get_entry(ShipIconGenerator.Category.SHIP, icon_id)
	if entry == null:
		return
	var tex: Texture2D = entry.get_texture(Color(0.0, 0.9, 1.0, 1.0))
	if tex == null:
		return

	# draw texture centered at origin, rotated around its center
	var rot: float = current_angle + PI / 2
	# upper-left of texture at (-half, -half), so center is at origin
	var half := 24.0
	var rect := Rect2(-half, -half, 48.0, 48.0)
	draw_set_transform(Vector2.ZERO, rot, Vector2.ONE)
	draw_texture_rect(tex, rect, false, Color.WHITE, true)
