extends Area2D

var direction: Vector2 = Vector2.RIGHT
var max_range: float = 700.0
var damage_per_tick: float = 12.0
var duration: float = 2.0
var crit_rate: float = 0.08
var crit_mult: float = 1.6
var game_manager: Node2D

var elapsed: float = 0.0
var tick_interval: float = 0.7
var tick_timer: float = 0.0
var hit_bodies: Array = []
var beam_width: float = 16.0
var base_width: float = 16.0
var damage_to_shield_mult: float = 1.0

var line2d: Node2D
var owner_player: Node2D = null
var current_target: Node2D = null
var target_world_pos: Vector2 = Vector2.ZERO
var beam_end_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	line2d = $Line2D
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_collision_shape()
	print("[LaserBeam] _ready called")

func _physics_process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return

	if is_instance_valid(owner_player):
		global_position = owner_player.global_position

	var closest = _find_closest_enemy()
	if closest and is_instance_valid(closest):
		current_target = closest
		direction = (closest.global_position - global_position).normalized()
		target_world_pos = closest.global_position
		rotation = direction.angle()
		beam_end_pos = target_world_pos
	else:
		beam_end_pos = global_position + direction * max_range
	rotation = direction.angle()
	_update_collision_shape()

	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_deal_damage_to_hits()

	if line2d:
		line2d.clear_points()
		line2d.add_point(Vector2.ZERO)
		var local_end = to_local(beam_end_pos)
		if local_end.length() > max_range:
			local_end = direction * max_range
		line2d.add_point(local_end)
		line2d.width = beam_width
		line2d.modulate = Color(0.0, 0.6, 1.0, 0.8)

func _deal_damage_to_hits() -> void:
	var to_remove: Array = []
	var enemies_to_damage: Array = []
	for body in hit_bodies:
		if not is_instance_valid(body):
			to_remove.append(body)
			continue
		enemies_to_damage.append(body)
	for body in enemies_to_damage:
		if body.has_method("take_laser_damage"):
			var is_crit = randf() < crit_rate
			var dmg = damage_per_tick * (crit_mult if is_crit else 1.0)
			body.take_laser_damage(dmg, is_crit, damage_to_shield_mult)
		elif body.has_method("take_damage"):
			var is_crit = randf() < crit_rate
			var dmg = damage_per_tick * (crit_mult if is_crit else 1.0)
			body.take_damage(dmg, is_crit)
	for b in to_remove:
		hit_bodies.erase(b)

func _update_collision_shape() -> void:
	var cs = $CollisionShape2D
	if cs and cs.shape is RectangleShape2D:
		var rect = cs.shape as RectangleShape2D
		rect.size.x = max_range
		rect.size.y = beam_width

func _find_closest_enemy() -> Node2D:
	if not game_manager or not is_instance_valid(game_manager):
		return null
	var enemy_root = game_manager.get("enemy_root")
	if not enemy_root or not is_instance_valid(enemy_root):
		return null
	var closest: Node2D = null
	var closest_dist_sq: float = INF
	for child in enemy_root.get_children():
		if not is_instance_valid(child):
			continue
		if not child is Node2D:
			continue
		var dist_sq = global_position.distance_squared_to(child.global_position)
		if dist_sq < closest_dist_sq:
			closest_dist_sq = dist_sq
			closest = child
	return closest

func setup(dir: Vector2, dmg: float, dur: float, cr: float, cm: float, gm: Node2D, width: float = 16.0, shield_mult: float = 1.0) -> void:
	game_manager = gm
	damage_per_tick = dmg
	duration = dur
	crit_rate = cr
	crit_mult = cm
	beam_width = width
	base_width = width
	damage_to_shield_mult = shield_mult
	elapsed = 0.0
	tick_timer = 0.0
	hit_bodies.clear()
	current_target = null
	target_world_pos = Vector2.ZERO
	beam_end_pos = Vector2.ZERO

	var init_target = _find_closest_enemy()
	if init_target and is_instance_valid(init_target):
		current_target = init_target
		direction = (init_target.global_position - global_position).normalized()
		target_world_pos = init_target.global_position
		beam_end_pos = init_target.global_position
	else:
		direction = dir.normalized()
		target_world_pos = global_position + direction * max_range
		beam_end_pos = global_position + direction * max_range
	rotation = direction.angle()
	_update_collision_shape()

func _on_body_entered(body: Node) -> void:
	if body == self or body == owner_player:
		return
	if not hit_bodies.has(body):
		hit_bodies.append(body)

func _on_body_exited(body: Node) -> void:
	hit_bodies.erase(body)
