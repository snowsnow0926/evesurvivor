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

var sprite: Sprite2D
var collision: CollisionShape2D
var pull_tween: Tween = null
var _damage_timer: float = 0.0

func _ready() -> void:
	sprite = $Sprite2D
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

func _process_black_hole(delta: float) -> void:
	_damage_timer += delta
	if _damage_timer >= 1.0:
		_damage_timer = 0.0
		_apply_damage_to_nearby()

	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < radius and dist > 10.0:
			var dir = (global_position - player.global_position).normalized()
			var force = pull_strength * (1.0 - dist / radius)
			player.velocity += dir * force * delta
			player.move_and_slide()

	if sprite:
		sprite.rotation += delta * 2.0

func _process_antimatter(delta: float) -> void:
	_damage_timer += delta
	if _damage_timer >= 1.0:
		_damage_timer = 0.0
		_apply_damage_to_nearby()

	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < radius * 0.5:
			_apply_large_damage()

	if sprite:
		var pulse = absf(sin(lifetime * 8.0))
		if sprite.modulate.a < 1.0:
			sprite.modulate.a = 0.5 + pulse * 0.5
		else:
			sprite.modulate.a = 0.5 + pulse * 0.5

func _process_mine_zone(delta: float) -> void:
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < radius and not has_dealt_damage:
			_explode_mine()

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
	has_dealt_damage = true

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
	_setup_collision_shape(rad)
	if sprite:
		sprite.modulate = Color(0.5, 0.0, 0.8, 0.7)

func setup_antimatter(pos: Vector2, gm: Node2D, p: Node2D, rad: float = 80.0, dur: float = 20.0) -> void:
	global_position = pos
	hazard_type = HazardType.ANTIMATTER_VORTEX
	game_manager = gm
	player = p
	radius = rad
	max_lifetime = dur
	damage_per_second = 30.0
	is_active = true
	_setup_collision_shape(rad)
	if sprite:
		sprite.modulate = Color(1.0, 0.3, 0.8, 0.8)

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
	if sprite:
		sprite.modulate = Color(1.0, 0.5, 0.0, 0.6)

func _on_body_entered(body: Node) -> void:
	pass

func _on_area_entered(area: Area2D) -> void:
	pass
