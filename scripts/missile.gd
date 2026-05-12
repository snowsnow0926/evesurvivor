extends Area2D

var target_dir: Vector2 = Vector2.ZERO
var damage: float = 15.0
var speed: float = 600.0
var crit_rate: float = 0.05
var crit_mult: float = 1.5
var game_manager: Node2D
var splash_radius: float = 0.0
var splash_count: int = 0

var lifetime: float = 0.0
var max_lifetime: float = 3.0
var traveled_distance: float = 0.0
var max_distance: float = 500.0
var max_tracking_time: float = 3.0
var tracking_time: float = 0.0

var current_target: Node2D = null
var initial_target_pos: Vector2 = Vector2.ZERO

var sprite: Sprite2D
var trail_points: Array = []
var trail_max_length: int = 8

var _frame_counter: int = 0

func _ready() -> void:
	sprite = $Sprite2D
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_frame_counter += 1

	lifetime += delta
	if lifetime > max_lifetime:
		queue_free()
		return

	if _frame_counter >= 3:
		_frame_counter = 0
		_update_target_tracking(delta)

	var move_step = target_dir * speed * delta
	position += move_step
	traveled_distance += move_step.length()
	if traveled_distance >= max_distance:
		queue_free()
		return

	if sprite:
		sprite.rotation = target_dir.angle()

	trail_points.push_front(global_position)
	if trail_points.size() > trail_max_length:
		trail_points.pop_back()

	queue_redraw()

func _update_target_tracking(delta: float) -> void:
	tracking_time += delta

	if tracking_time > max_tracking_time:
		return

	if is_instance_valid(current_target):
		if _is_target_alive(current_target):
			target_dir = (current_target.global_position - global_position).normalized()
		else:
			current_target = _find_nearest_enemy()
			if current_target:
				target_dir = (current_target.global_position - global_position).normalized()
	else:
		current_target = _find_nearest_enemy()
		if current_target:
			target_dir = (current_target.global_position - global_position).normalized()

func _is_target_alive(target: Node2D) -> bool:
	if not is_instance_valid(target):
		return false
	if target.has_method("is_dead"):
		return not target.is_dead()
	if target.has_method("get_hp"):
		return target.get_hp() > 0
	if target.has_method("hp"):
		return target.get("hp") > 0
	return true

func _find_nearest_enemy() -> Node2D:
	if not game_manager or not is_instance_valid(game_manager):
		return null
	var enemy_root = game_manager.get("enemy_root")
	if not enemy_root or not is_instance_valid(enemy_root):
		return null

	var nearest: Node2D = null
	var nearest_dist = max_distance
	for enemy in enemy_root.get_children():
		if not is_instance_valid(enemy) or not enemy is CharacterBody2D:
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest

func _draw() -> void:
	if trail_points.size() < 2:
		return

	var width = 6.0
	for i in range(trail_points.size() - 1):
		var alpha = 1.0 - float(i) / float(trail_points.size())
		var color = Color(1.0, 0.6, 0.1, alpha * 0.7)
		var start = trail_points[i] - global_position
		var end = trail_points[i + 1] - global_position
		draw_line(start, end, color, width * alpha, true)

func setup_target_direction(dir: Vector2, dmg: float, spd: float, cr: float, cm: float, gm: Node2D, splash_rad: float = 0.0, splash_cnt: int = 0, range_limit: float = 500.0) -> void:
	target_dir = dir.normalized()
	damage = dmg
	speed = spd
	crit_rate = cr
	crit_mult = cm
	game_manager = gm
	splash_radius = splash_rad
	splash_count = splash_cnt
	max_distance = range_limit
	current_target = null
	tracking_time = 0.0
	_frame_counter = 0

func setup_with_target(dir: Vector2, dmg: float, spd: float, cr: float, cm: float, gm: Node2D, target: Node2D, splash_rad: float = 0.0, splash_cnt: int = 0, range_limit: float = 500.0) -> void:
	setup_target_direction(dir, dmg, spd, cr, cm, gm, splash_rad, splash_cnt, range_limit)
	current_target = target
	initial_target_pos = target.global_position
	_frame_counter = 0

func _on_body_entered(body: Node) -> void:
	if body == self:
		return
	if not body is CharacterBody2D:
		return
	if body.has_method("take_damage"):
		var is_crit = randf() < crit_rate
		var final_damage = damage * (crit_mult if is_crit else 1.0)
		body.take_damage(final_damage, is_crit)
		if splash_radius > 0.0:
			_apply_splash_damage(body.global_position, final_damage)
		_spawn_explosion(global_position)
	queue_free()

func _apply_splash_damage(hit_pos: Vector2, base_damage: float) -> void:
	if not game_manager or not is_instance_valid(game_manager):
		return
	var enemy_root = game_manager.get("enemy_root")
	if not enemy_root or not is_instance_valid(enemy_root):
		return
	var splash_dmg = base_damage * 0.5
	var hit_count = 0
	for enemy in enemy_root.get_children():
		if not is_instance_valid(enemy) or not enemy is CharacterBody2D or not enemy.has_method("take_damage"):
			continue
		if enemy == self:
			continue
		var dist = hit_pos.distance_to(enemy.global_position)
		if dist <= splash_radius:
			enemy.take_damage(splash_dmg, false)
			hit_count += 1
			if hit_count >= splash_count:
				break

func _spawn_explosion(pos: Vector2) -> void:
	if not game_manager or not is_instance_valid(game_manager):
		return
	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return

	var explosion = CPUParticles2D.new()
	explosion.amount = 30
	explosion.lifetime = 0.4
	explosion.explosiveness = 0.8
	explosion.emission_shape = 1
	explosion.emission_sphere_radius = splash_radius if splash_radius > 0.0 else 40.0
	explosion.direction = Vector2(0, -1)
	explosion.spread = 180.0
	explosion.initial_velocity_min = 100.0
	explosion.initial_velocity_max = 200.0
	explosion.scale_amount_min = 4.0
	explosion.scale_amount_max = 8.0
	explosion.color = Color(1.0, 0.5, 0.1, 1.0)
	explosion.gravity = Vector2(0, 200)
	explosion.one_shot = true

	explosion.global_position = pos
	bullet_root.add_child(explosion)

	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.timeout.connect(explosion.queue_free)
	timer.timeout.connect(timer.queue_free)
	bullet_root.add_child(timer)
	timer.start()
