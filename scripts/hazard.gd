class_name Hazard
extends Area2D

enum HazardType { BLACK_HOLE, ANTIMATTER_VORTEX, MINE_ZONE }

var hazard_type: HazardType = HazardType.BLACK_HOLE

var player: Node2D = null
var game_manager: Node2D = null
var damage_per_second: float = 20.0
var pull_strength: float = 150.0
var radius: float = 120.0
var lifetime: float = 0.0
var max_lifetime: float = 30.0
var is_active: bool = false
var has_dealt_damage: bool = false
var _has_exploded: bool = false

var collision: CollisionShape2D
var pull_tween: Tween = null
var _damage_timer: float = 0.0
var _rotation_angle: float = 0.0

func _ready() -> void:
	collision = $CollisionShape2D
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()
		return

	match hazard_type:
		HazardType.BLACK_HOLE:
			_process_black_hole(delta)
		HazardType.ANTIMATTER_VORTEX:
			_process_antimatter(delta)
		HazardType.MINE_ZONE:
			_process_mine_zone(delta)

	queue_redraw()

func _process_black_hole(delta: float) -> void:
	_damage_timer += delta
	if _damage_timer >= 1.0:
		_damage_timer = 0.0
		_apply_damage_to_nearby()

	_rotation_angle += delta * 2.0

	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < radius and dist > 10.0:
			var dir = (global_position - player.global_position).normalized()
			var force = pull_strength * (1.0 - dist / radius)
			player.velocity += dir * force * delta
			player.move_and_slide()

func _process_antimatter(delta: float) -> void:
	_damage_timer += delta
	if _damage_timer >= 1.0:
		_damage_timer = 0.0
		_apply_damage_to_nearby()

	_rotation_angle += delta * 3.0

	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < radius * 0.5:
			_apply_large_damage()

func _process_mine_zone(delta: float) -> void:
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < radius and not has_dealt_damage and not _has_exploded:
			_explode_mine()

func _draw() -> void:
	if not is_active:
		return

	var fade = 1.0
	if lifetime > max_lifetime - 3.0:
		fade = (max_lifetime - lifetime) / 3.0

	match hazard_type:
		HazardType.BLACK_HOLE:
			_draw_black_hole()
		HazardType.ANTIMATTER_VORTEX:
			_draw_antimatter()
		HazardType.MINE_ZONE:
			_draw_mine_zone(fade)

	match hazard_type:
		HazardType.BLACK_HOLE:
			draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(0.6, 0.0, 0.9, 0.15 * fade), 2.0, true)
			draw_arc(Vector2.ZERO, radius * 0.6, 0, TAU, 64, Color(0.4, 0.0, 0.7, 0.2 * fade), 1.5, true)
			draw_arc(Vector2.ZERO, radius * 0.3, 0, TAU, 64, Color(0.1, 0.0, 0.2, 0.4 * fade), 1.0, true)
		HazardType.ANTIMATTER_VORTEX:
			draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(1.0, 0.3, 0.8, 0.12 * fade), 2.0, true)
			draw_arc(Vector2.ZERO, radius * 0.5, 0, TAU, 64, Color(1.0, 0.5, 1.0, 0.2 * fade), 1.5, true)
		HazardType.MINE_ZONE:
			draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(1.0, 0.5, 0.0, 0.1 * fade), 1.5, true)
			draw_arc(Vector2.ZERO, radius * 0.7, 0, TAU, 64, Color(1.0, 0.3, 0.0, 0.08 * fade), 1.0, true)

func _draw_black_hole() -> void:
	var t = _rotation_angle
	for i in range(6):
		var angle = t + i * TAU / 6.0
		var r = radius * (0.2 + 0.12 * i)
		var inner = Vector2.from_angle(angle) * r
		var outer = Vector2.from_angle(angle + TAU * 0.35) * (r + radius * 0.25)
		var col = Color(0.7, 0.0, 1.0, 0.5 - i * 0.06)
		draw_line(inner, outer, col, 2.5 - i * 0.3, true)

	draw_circle(Vector2.ZERO, radius * 0.15, Color(0.05, 0.0, 0.1, 0.9))
	draw_circle(Vector2.ZERO, radius * 0.08, Color(0.0, 0.0, 0.0, 1.0))

func _draw_antimatter() -> void:
	var pulse = absf(sin(lifetime * 8.0)) * 0.3 + 0.7
	var inner_col = Color(1.0, 0.4, 0.9, pulse * 0.9)
	draw_circle(Vector2.ZERO, radius * 0.2 * pulse, inner_col)
	draw_circle(Vector2.ZERO, radius * 0.1, Color(1.0, 1.0, 1.0, 0.8))

	var t = _rotation_angle
	for i in range(5):
		var angle = t + i * TAU / 5.0
		var pos = Vector2.from_angle(angle) * radius * 0.5
		draw_circle(pos, 4.0, Color(1.0, 0.6, 1.0, 0.7))

	for i in range(8):
		var angle = t * 1.5 + i * TAU / 8.0
		var pos = Vector2.from_angle(angle) * radius * 0.75
		draw_circle(pos, 2.5, Color(1.0, 0.3, 0.8, 0.5))

func _draw_mine_zone(fade: float) -> void:
	var seed_val = hash(global_position)
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val

	for i in range(12):
		var angle = rng.randf_range(0, TAU)
		var dist = rng.randf_range(0.15, 0.85) * radius
		var pos = Vector2.from_angle(angle) * dist
		var size = rng.randf_range(3.0, 6.0)
		var col_val = rng.randf_range(0.8, 1.0)
		draw_circle(pos, size, Color(1.0, col_val, 0.0, 0.85))
		draw_circle(pos, size * 0.5, Color(1.0, 0.9, 0.5, 0.9))

	for i in range(6):
		var angle = i * TAU / 6.0 + lifetime * 0.5
		var pos = Vector2.from_angle(angle) * radius * 0.9
		draw_circle(pos, 5.0, Color(1.0, 0.2, 0.0, 0.6 * fade))

func _apply_damage_to_nearby() -> void:
	if not game_manager or not is_instance_valid(game_manager):
		return
	var enemy_root = game_manager.get("enemy_root")
	if not enemy_root or not is_instance_valid(enemy_root):
		return
	for child in enemy_root.get_children():
		if not is_instance_valid(child):
			continue
		if not child is Node2D:
			continue
		var dist = global_position.distance_to(child.global_position)
		if dist < radius:
			if child.has_method("take_damage"):
				child.take_damage(damage_per_second, false)

func _apply_large_damage() -> void:
	if not game_manager or not is_instance_valid(game_manager):
		return
	if player and is_instance_valid(player) and player.has_method("on_player_take_damage"):
		player.on_player_take_damage(damage_per_second * 3.0)
	queue_free()

func _explode_mine() -> void:
	if not game_manager or not is_instance_valid(game_manager):
		queue_free()
		return
	_has_exploded = true
	has_dealt_damage = true

	_spawn_explosion_effect()

	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < radius:
			if player.has_method("on_player_take_damage"):
				player.on_player_take_damage(damage_per_second * 5.0)

	var enemy_root = game_manager.get("enemy_root")
	if enemy_root and is_instance_valid(enemy_root):
		for child in enemy_root.get_children():
			if not is_instance_valid(child):
				continue
			if not child is Node2D:
				continue
			var dist = global_position.distance_to(child.global_position)
			if dist < radius and child.has_method("take_damage"):
				child.take_damage(damage_per_second * 3.0, false)

	queue_free()

func _spawn_explosion_effect() -> void:
	var effect = GPUParticles2D.new()
	effect.global_position = global_position
	effect.amount = 30
	effect.lifetime = 0.6
	effect.explosiveness = 0.8
	effect.randomness = 0.5
	effect.local_coords = false
	effect.one_shot = true

	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = radius * 0.3
	mat.direction = Vector3(1, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = radius * 0.8
	mat.initial_velocity_max = radius * 1.5
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	mat.color = Color(1.0, 0.5, 0.0, 1.0)
	mat.lifetime_randomness = 0.3
	mat.gravity = Vector3.ZERO
	effect.process_material = mat
	effect.modulate = Color(1.0, 0.6, 0.0, 1.0)

	var parent = get_parent()
	if parent:
		parent.add_child(effect)
		effect.emitting = true
		effect.tree_exited.connect(effect.queue_free, CONNECT_ONE_SHOT)

func _setup_collision_shape(rad: float) -> void:
	if not collision:
		return
	var circle = CircleShape2D.new()
	circle.radius = rad
	collision.shape = circle

func setup_black_hole(pos: Vector2, gm: Node2D, p: Node2D, rad: float = 120.0, dur: float = 30.0) -> void:
	global_position = pos
	hazard_type = HazardType.BLACK_HOLE
	game_manager = gm
	player = p
	radius = rad
	max_lifetime = dur
	damage_per_second = 15.0
	pull_strength = 150.0
	is_active = true
	_rotation_angle = randf_range(0, TAU)
	_setup_collision_shape(rad)
	queue_redraw()

func setup_antimatter(pos: Vector2, gm: Node2D, p: Node2D, rad: float = 80.0, dur: float = 20.0) -> void:
	global_position = pos
	hazard_type = HazardType.ANTIMATTER_VORTEX
	game_manager = gm
	player = p
	radius = rad
	max_lifetime = dur
	damage_per_second = 30.0
	is_active = true
	_rotation_angle = randf_range(0, TAU)
	_setup_collision_shape(rad)
	queue_redraw()

func setup_mine_zone(pos: Vector2, gm: Node2D, p: Node2D, rad: float = 100.0, dur: float = 25.0) -> void:
	global_position = pos
	hazard_type = HazardType.MINE_ZONE
	game_manager = gm
	player = p
	radius = rad
	max_lifetime = dur
	damage_per_second = 25.0
	is_active = true
	has_dealt_damage = false
	_setup_collision_shape(rad)
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	pass

func _on_area_entered(area: Area2D) -> void:
	pass
