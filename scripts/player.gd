extends CharacterBody2D

const DEBUG := false

func _debug(msg: String) -> void:
	if DEBUG:
		print("[Player] ", msg)

const ShipData = preload("res://resources/ship_data.gd")
const WeaponData = preload("res://resources/weapon_data.gd")
const ShipIconGenerator = preload("res://scripts/ship_icon_generator.gd")

var game_manager: Node2D

var move_speed: float = 320.0
var dodge: float = 0.1
var crit_rate: float = 0.05
var crit_mult: float = 1.5
var lifesteal: float = 0.0
var shield_max: float = 50.0
var shield: float = 50.0
var shield_regen: float = 4.0
var hp: int = 100
var splash_radius: float = 0.0
var splash_count: int = 0
var mobile_fire_mult: float = 1.0
var _is_moving: bool = false
var _stationary_timer: float = 0.0
var _is_stationary: bool = false
var silent_hunter_active: bool = false
var silent_hunter_level: int = 0
var race_talents: Array = []
var default_weapon_scene: String = "res://scenes/Missile.tscn"

var active_weapons: Array = []
var weapon_fire_timers: Dictionary = {}

var missile_speed: float = 600.0
var missile_range: float = 500.0
var spread_count: int = 1
var missile_burst_timers: Dictionary = {}
var missile_burst_counts: Dictionary = {}
const MISSILE_BURST_INTERVAL: float = 0.1

var cannon_fire_interval: float = 1.2
var cannon_damage: float = 25.0
var cannon_pierce_count: int = 1
var cannon_explode_chance: float = 0.0
var cannon_bloodthirst: int = 0

var railgun_damage: float = 30.0
var railgun_speed: float = 1000.0
var railgun_range: float = 400.0
var railgun_fire_interval: float = 0.6
var railgun_crit_bonus: float = 0.0
var railgun_multi_count: int = 1
var railgun_burst_count: int = 0
var railgun_burst_timer: float = 0.0
const RAILGUN_BURST_INTERVAL: float = 0.1

var laser_damage: float = 12.0
var laser_duration: float = 2.0
var laser_width: float = 16.0
var laser_fire_interval: float = 2.5
var laser_shield_mult: float = 1.0

var damage: float = 15.0

var injured_timer: float = 0.0
var injured_duration: float = 2.0
var is_injured: bool = false
var _physics_tick_counter: int = 0

var fire_timer: float = 0.0
var current_angle: float = 0.0
var target_angle: float = 0.0
var turn_time: float = 0.12

var polygon: Node2D
var ship_sprite: Sprite2D

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
	var icon_id: String = _SHIP_ICON_MAP.get(sid, "frigate")
	var entry: ShipIconGenerator.IconEntry = ShipIconGenerator.get_entry(ShipIconGenerator.Category.SHIP, icon_id)
	if entry == null:
		return
	var tex: Texture2D = entry.get_texture()
	if tex != null and ship_sprite != null:
		ship_sprite.texture = tex
		ship_sprite.visible = true
		if polygon != null:
			polygon.visible = false
	else:
		# fall back to polygon
		if entry.path.is_empty():
			return
		var polygon_points := _build_polygon_from_path(entry.path)
		if polygon_points.is_empty():
			return
		if polygon != null:
			polygon.visible = false
		if ship_sprite != null:
			ship_sprite.visible = false
		queue_redraw()

func _build_polygon_from_path(path: Array) -> PackedVector2Array:
	var closed_polygons: Array[PackedVector2Array] = []
	var current_open: Array[Vector2] = []
	var last_pt := Vector2.ZERO
	var sub_start := Vector2.ZERO

	for cmd: Array in path:
		if cmd.is_empty():
			continue
		var t: String = cmd[0]
		match t:
			"M":
				if not current_open.is_empty() and current_open.size() >= 2:
					closed_polygons.append(PackedVector2Array(current_open))
				current_open.clear()
				last_pt = Vector2(cmd[1], cmd[2])
				current_open.append(last_pt)
				sub_start = last_pt
			"L":
				var p: Vector2 = Vector2(cmd[1], cmd[2])
				current_open.append(p)
				last_pt = p
			"Q":
				if cmd.size() >= 5:
					var p0 := last_pt
					var p1 := Vector2(cmd[1], cmd[2])
					var p2 := Vector2(cmd[3], cmd[4])
					for j: int in range(1, 13):
						var tt: float = float(j) / 12.0
						var mt: float = 1.0 - tt
						var pt := Vector2(
							mt * mt * p0.x + 2.0 * mt * tt * p1.x + tt * tt * p2.x,
							mt * mt * p0.y + 2.0 * mt * tt * p1.y + tt * tt * p2.y
						)
						current_open.append(pt)
					last_pt = p2
			"Z":
				if not current_open.is_empty() and current_open.size() >= 2:
					current_open.append(sub_start)

	if not current_open.is_empty() and current_open.size() >= 2:
		closed_polygons.append(PackedVector2Array(current_open))

	if closed_polygons.is_empty():
		return PackedVector2Array()

	var primary := closed_polygons[0]
	var icon_size: float = ShipIconGenerator.ICON_SIZE
	var icon_viewbox: float = ShipIconGenerator.ICON_VIEWBOX
	var scale_val: float = icon_size / icon_viewbox
	var offset := Vector2(-50.0 * scale_val, -50.0 * scale_val)

	var result := PackedVector2Array()
	for p: Vector2 in primary:
		result.append(p * scale_val + offset)
	return result

func _ready() -> void:
	polygon = $Polygon2D
	ship_sprite = $ShipSprite
	_debug("_ready called, polygon=" + str(polygon) + ", sprite=" + str(ship_sprite))
	_debug("viewport size=" + str(get_viewport_rect().size))
	if polygon:
		polygon.rotation = -PI / 2
	_debug("polygon setup done")
	set_ship_icon()

func init_weapons() -> void:
	active_weapons.clear()
	weapon_fire_timers.clear()

	var scene_to_weapon_type = {
		"res://scenes/Missile.tscn": WeaponData.WeaponID.MISSILE,
		"res://scenes/CannonBullet.tscn": WeaponData.WeaponID.CANNON,
		"res://scenes/RailgunBullet.tscn": WeaponData.WeaponID.RAILGUN,
		"res://scenes/LaserBeam.tscn": WeaponData.WeaponID.LASER,
	}

	var sid = int(GameState.selected_ship_id)
	if sid == 0:
		sid = ShipData.ShipID.FRIGATE
	var equipped_list = GameState.equipped_weapons.get(sid)
	_debug("init_weapons: selected_ship_id=" + str(sid) + " equipped_list=" + str(equipped_list))
	var added_any = false
	var item_id: int = -1
	var weapon_type_map: Dictionary = {}

	if equipped_list is Array and not equipped_list.is_empty():
		for equipped_dict in equipped_list:
			if equipped_dict is Dictionary and equipped_dict.has("scene_path"):
				var scene_path = equipped_dict.get("scene_path", default_weapon_scene)
				var weapon_type = scene_to_weapon_type.get(scene_path, WeaponData.WeaponID.MISSILE)
				var quality = equipped_dict.get("quality", 0)
				if equipped_dict.has("shop_item_id"):
					item_id = equipped_dict.get("shop_item_id")
					weapon_type_map = {
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
				if weapon_type_map:
					weapon_type = weapon_type_map.get(item_id, weapon_type)
				var weapon_data = WeaponData.get_weapon(weapon_type, quality)
				active_weapons.append(weapon_data)
				weapon_fire_timers[weapon_data.weapon_id] = 0.0
				added_any = true

	if not added_any:
		_debug("NO shop weapons found, using race default: " + default_weapon_scene)
		var weapon_type = scene_to_weapon_type.get(default_weapon_scene, WeaponData.WeaponID.MISSILE)
		var weapon_data = WeaponData.get_weapon(weapon_type)
		active_weapons.append(weapon_data)
		weapon_fire_timers[weapon_data.weapon_id] = 0.0
	else:
		_debug("loaded " + str(active_weapons.size()) + " weapon(s) from shop")

	cannon_fire_interval = 1.2
	cannon_pierce_count = 1
	cannon_explode_chance = 0.0
	cannon_bloodthirst = 0
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

func _physics_process(delta: float) -> void:
	_physics_tick_counter += 1
	if DEBUG and _physics_tick_counter % 120 == 0:
		_debug("alive tick=" + str(_physics_tick_counter) + _debug_player_state())
	if game_manager and game_manager.is_game_over:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_update_injured_state(delta)
	_update_movement(delta)
	_update_firing(delta)

func _debug_player_state() -> String:
	var bullet_root = game_manager.get("bullet_root") if game_manager else null
	var bullet_count = bullet_root.get_child_count() if bullet_root and is_instance_valid(bullet_root) else -1
	return " active_weapons=%d bullet_count=%d" % [active_weapons.size(), bullet_count]

func _update_injured_state(delta: float) -> void:
	if is_injured:
		injured_timer -= delta
		if injured_timer <= 0.0:
			is_injured = false

func _update_movement(delta: float) -> void:
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

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
		silent_hunter_active = false
	else:
		_is_moving = false
		_stationary_timer += delta
		if _stationary_timer >= 0.2 and velocity.length() < 5.0:
			_is_stationary = true
			silent_hunter_active = true
		else:
			_is_stationary = false
			silent_hunter_active = false

	velocity = input_dir * move_speed
	move_and_slide()

	if ship_sprite and ship_sprite.visible:
		ship_sprite.rotation = current_angle + PI / 2
	elif polygon:
		polygon.rotation = current_angle + PI / 2
	if not ship_sprite or not ship_sprite.visible:
		queue_redraw()

func _update_firing(delta: float) -> void:
	if active_weapons.is_empty():
		return
	for weapon in active_weapons:
		var wt = weapon.weapon_id
		if not weapon_fire_timers.has(wt):
			weapon_fire_timers[wt] = 0.0
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
			if weapon_fire_timers[wt] >= interval:
				weapon_fire_timers[wt] = 0.0
				_fire_weapon(weapon)

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
		var mult = 1.0
		if silent_hunter_active:
			mult = pow(0.85, float(silent_hunter_level))
		if _is_moving and game_manager and game_manager.cannon_rush_level > 0:
			mult *= (1.0 - 0.15 * float(game_manager.cannon_rush_level))
		return base * mult
	elif wt in cannon_ids:
		var interval = cannon_fire_interval
		if game_manager:
			if _is_moving and game_manager.cannon_rush_level > 0:
				interval *= (1.0 - 0.15 * float(game_manager.cannon_rush_level))
			if is_injured and game_manager.cannon_vengeance_level > 0:
				interval *= (1.0 - 0.15 * float(game_manager.cannon_vengeance_level))
		return interval
	elif wt in railgun_ids:
		return railgun_fire_interval
	elif wt in laser_ids:
		return laser_fire_interval
	return base

func _update_railgun_firing(delta: float, weapon: WeaponData) -> void:
	var wt = weapon.weapon_id
	if railgun_burst_count > 0:
		railgun_burst_timer += delta
		if railgun_burst_timer >= RAILGUN_BURST_INTERVAL:
			railgun_burst_timer = 0.0
			railgun_burst_count -= 1
			var target_pos = _find_closest_enemy(weapon.range)
			if target_pos != Vector2.ZERO:
				SoundManager.play_sfx("shoot_railgun")
				_fire_single_railgun(target_pos)
	else:
		var interval = _get_fire_interval(weapon)
		if weapon_fire_timers[wt] >= interval:
			weapon_fire_timers[wt] = 0.0
			var target_pos = _find_closest_enemy(weapon.range)
			if target_pos != Vector2.ZERO:
				railgun_burst_count = railgun_multi_count - 1
				railgun_burst_timer = 0.0
				SoundManager.play_sfx("shoot_railgun")
				_fire_single_railgun(target_pos)

func get_talent_bonus(talent_type: String) -> float:
	for talent in race_talents:
		if talent.get("type") == talent_type:
			return talent.get("value", 0.0)
	return 0.0

func _fire_weapon(weapon: WeaponData) -> void:
	if not game_manager or not is_instance_valid(game_manager):
		_debug("FAIL: no game_manager")
		return
	var enemy_root = game_manager.get("enemy_root")
	if not enemy_root or not is_instance_valid(enemy_root):
		_debug("FAIL: no enemy_root")
		return

	var target_pos = _find_closest_enemy(weapon.range)
	if target_pos == Vector2.ZERO:
		_debug("FAIL: no target found, range=" + str(weapon.range) + " enemy_count=" + str(enemy_root.get_child_count()))
		return

	match weapon.weapon_id:
		WeaponData.WeaponID.MISSILE or WeaponData.WeaponID.SMALL_MISSILE or WeaponData.WeaponID.MEDIUM_MISSILE or WeaponData.WeaponID.LARGE_MISSILE or WeaponData.WeaponID.FLAGSHIP_MISSILE:
			_fire_missiles_at(target_pos, weapon)
		WeaponData.WeaponID.CANNON or WeaponData.WeaponID.SMALL_CANNON or WeaponData.WeaponID.MEDIUM_CANNON or WeaponData.WeaponID.LARGE_CANNON or WeaponData.WeaponID.FLAGSHIP_CANNON:
			_fire_cannon_at(target_pos)
		WeaponData.WeaponID.RAILGUN or WeaponData.WeaponID.SMALL_RAILGUN or WeaponData.WeaponID.MEDIUM_RAILGUN or WeaponData.WeaponID.LARGE_RAILGUN or WeaponData.WeaponID.FLAGSHIP_RAILGUN:
			_fire_railgun_at(target_pos)
		WeaponData.WeaponID.LASER or WeaponData.WeaponID.SMALL_LASER or WeaponData.WeaponID.MEDIUM_LASER or WeaponData.WeaponID.LARGE_LASER or WeaponData.WeaponID.FLAGSHIP_LASER:
			_fire_laser_at(target_pos)

func _find_closest_enemy(max_range: float) -> Vector2:
	var enemy_root = game_manager.get("enemy_root")
	if not enemy_root:
		return Vector2.ZERO
	var closest: Node2D = null
	var closest_dist = max_range
	for enemy in enemy_root.get_children():
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy
	if closest:
		return closest.global_position
	return Vector2.ZERO

func _fire_missiles_at(target_pos: Vector2, weapon) -> void:
	_debug("firing missiles at " + str(target_pos))
	SoundManager.play_sfx("shoot_missile")
	if not game_manager:
		return
	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return
	var missile_scene_path = "res://scenes/Missile.tscn"
	if not ResourceLoader.exists(missile_scene_path):
		return

	_spawn_single_missile(target_pos, missile_scene_path, bullet_root)

	var total = spread_count
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
		return

	var interval = _get_fire_interval(weapon)
	if weapon_fire_timers[wt] >= interval:
		weapon_fire_timers[wt] = 0.0
		_fire_missiles_at(_find_closest_enemy(weapon.range), weapon)

func _fire_single_missile_for_burst(weapon) -> void:
	var target_pos = _find_closest_enemy(weapon.range)
	if target_pos == Vector2.ZERO:
		return
	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return
	var missile_scene_path = "res://scenes/Missile.tscn"
	_spawn_single_missile(target_pos, missile_scene_path, bullet_root)

func _spawn_single_missile(target_pos: Vector2, missile_scene_path: String, bullet_root: Node) -> void:
	var base_angle = global_position.angle_to_point(target_pos)
	var missile_scene = load(missile_scene_path)
	var missile = missile_scene.instantiate()
	bullet_root.add_child(missile)
	missile.global_position = global_position
	missile.setup_target_direction(Vector2.from_angle(base_angle), damage, missile_speed, crit_rate, crit_mult, game_manager, splash_radius, splash_count, missile_range)

func _fire_cannon_at(target_pos: Vector2) -> void:
	SoundManager.play_sfx("shoot_cannon")
	if not game_manager:
		return
	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return
	var cannon_scene_path = "res://scenes/CannonBullet.tscn"
	if not ResourceLoader.exists(cannon_scene_path):
		return

	var dir = global_position.angle_to_point(target_pos)
	var bullet_count = 1 + cannon_bloodthirst
	var spacing = 10.0

	for i in range(bullet_count):
		var offset_x = (i - (bullet_count - 1) * 0.5) * spacing
		var spawn_pos = global_position + Vector2.from_angle(dir).rotated(PI / 2) * offset_x

		var cannon_scene = load(cannon_scene_path)
		var bullet = cannon_scene.instantiate()
		bullet_root.add_child(bullet)
		bullet.global_position = spawn_pos

		bullet.setup(
			Vector2.from_angle(dir),
			cannon_damage,
			800.0,
			400.0,
			crit_rate,
			crit_mult,
			game_manager,
			cannon_pierce_count,
			0.2,
			cannon_explode_chance,
			80.0
		)

func _fire_railgun_at(target_pos: Vector2) -> void:
	SoundManager.play_sfx("shoot_railgun")
	if not game_manager:
		return
	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return
	var railgun_scene_path = "res://scenes/RailgunBullet.tscn"
	if not ResourceLoader.exists(railgun_scene_path):
		return

	_fire_single_railgun(target_pos)

func _fire_single_railgun(target_pos: Vector2) -> void:
	if not game_manager:
		return
	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return
	var railgun_scene_path = "res://scenes/RailgunBullet.tscn"
	if not ResourceLoader.exists(railgun_scene_path):
		return

	var base_angle = global_position.angle_to_point(target_pos)
	var count = railgun_multi_count
	var spacing = 10.0

	for i in range(count):
		var offset_idx = i - (count - 1) * 0.5
		var final_angle = base_angle
		if count > 1:
			final_angle = base_angle + deg_to_rad(offset_idx * spacing)
		else:
			final_angle = base_angle

		var railgun_scene = load(railgun_scene_path)
		var bullet = railgun_scene.instantiate()
		bullet_root.add_child(bullet)
		bullet.global_position = global_position

		var final_crit_rate = crit_rate + railgun_crit_bonus
		bullet.setup(
			Vector2.from_angle(final_angle),
			railgun_damage,
			railgun_speed,
			railgun_range,
			final_crit_rate,
			crit_mult,
			game_manager
		)

func _fire_laser_at(target_pos: Vector2) -> void:
	SoundManager.play_sfx("shoot_laser")
	if not game_manager:
		return
	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return
	var laser_scene_path = "res://scenes/LaserBeam.tscn"
	if not ResourceLoader.exists(laser_scene_path):
		return

	var laser_scene = load(laser_scene_path)
	var laser = laser_scene.instantiate()
	bullet_root.add_child(laser)
	laser.global_position = global_position

	var dir = (target_pos - global_position).normalized()
	laser.owner_player = self
	laser.setup(
		dir,
		laser_damage,
		laser_duration,
		crit_rate,
		crit_mult,
		game_manager,
		laser_width,
		laser_shield_mult
	)

func apply_race_data(race: RaceData) -> void:
	hp = int(race.base_hp)
	shield_max = race.shield_max
	shield = race.shield_max
	shield_regen = race.shield_regen
	move_speed = race.move_speed
	dodge = race.dodge_rate
	crit_rate = race.crit_rate
	crit_mult = race.crit_mult
	default_weapon_scene = race.base_weapon_scene
	race_talents = race.talents
	init_weapons()
	_apply_race_talents()
	_apply_armor_bonuses()
	_debug("Applied race data: " + race.display_name)
	set_ship_icon()

func _apply_race_talents() -> void:
	for talent in race_talents:
		match talent.get("type"):
			"cannon_fire_rate":
				cannon_fire_interval *= (1.0 - talent.get("value", 0.0))
			"missile_range":
				missile_range *= (1.0 + talent.get("value", 0.0))
			"railgun_crit":
				railgun_crit_bonus += talent.get("value", 0.0)
			"laser_width_duration":
				laser_width *= (1.0 + talent.get("value", 0.0))
				laser_duration *= (1.0 + talent.get("value", 0.0))
			_:
				pass

func _apply_armor_bonuses() -> void:
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE
	var armor = GameState.equipped_armor.get(ship_id, {})
	if armor is Dictionary and not armor.is_empty():
		shield_max += armor.get("shield_bonus", 0.0)
		shield_regen += armor.get("shield_regen_bonus", 0.0)
		shield = shield_max

func set_game_manager(gm: Node2D) -> void:
	game_manager = gm

func on_player_take_damage(amount: float) -> void:
	var final_amount = amount
	for talent in race_talents:
		if talent.get("type") == "damage_reduction":
			final_amount *= (1.0 - talent.get("value", 0.0))
	if game_manager and is_instance_valid(game_manager) and game_manager.has_method("on_player_take_damage"):
		game_manager.on_player_take_damage(final_amount)

	is_injured = true
	injured_timer = injured_duration

func sync_from_game_manager(gm: Node2D) -> void:
	move_speed = gm.player_move_speed
	damage = gm.player_damage
	shield_max = gm.player_shield_max
	shield = gm.player_shield
	shield_regen = gm.player_shield_regen
	dodge = gm.player_dodge
	crit_rate = gm.player_crit_rate
	crit_mult = gm.player_crit_mult
	missile_speed = gm.missile_speed
	missile_range = gm.missile_range
	spread_count = gm.spread_count
	lifesteal = gm.player_lifesteal
	hp = gm.player_hp
	splash_radius = gm.missile_splash_radius
	splash_count = gm.missile_splash_count
	mobile_fire_mult = gm.mobile_fire_mult
	cannon_fire_interval = gm.cannon_fire_interval
	cannon_damage = gm.cannon_damage
	cannon_pierce_count = gm.cannon_pierce_count
	cannon_explode_chance = gm.cannon_explode_chance
	cannon_bloodthirst = gm.cannon_bloodthirst
	silent_hunter_level = gm.silent_hunter_level
	railgun_damage = gm.railgun_damage
	railgun_speed = gm.railgun_speed
	railgun_range = gm.railgun_range
	railgun_fire_interval = gm.railgun_fire_interval
	railgun_crit_bonus = gm.railgun_crit_bonus
	railgun_multi_count = gm.railgun_multi_count
	laser_damage = gm.laser_damage
	laser_duration = gm.laser_duration
	laser_width = gm.laser_width
	laser_fire_interval = gm.laser_fire_interval
	laser_shield_mult = gm.laser_shield_mult

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

func _input(event: InputEvent) -> void:
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
