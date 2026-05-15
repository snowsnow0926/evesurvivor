extends Area2D

const _SCENE_DEATH_EXPLOSION: PackedScene = preload("res://scenes/DeathExplosion.tscn")

var target_dir: Vector2 = Vector2.ZERO
var damage: float = 15.0
var speed: float = 600.0
var crit_rate: float = 0.05
var crit_mult: float = 1.5
var game_manager: Node2D
var player: Node2D = null
var splash_radius: float = 0.0
var splash_count: int = 0

const MAX_BULLETS: int = 500
const FAR_DISTANCE: float = 400.0
const FAR_CHECK_INTERVAL: int = 10

var _bullet_counter: int = 0
var _far_bullet_degraded: bool = false
var _fps_check_timer: float = 0.0
var _last_fps: float = 60.0
var _low_fps_mode: bool = false
var _far_check_counter: int = 0

var lifetime: float = 0.0
var max_lifetime: float = 3.0
var traveled_distance: float = 0.0
var max_distance: float = 500.0
var max_tracking_time: float = 3.0
var tracking_time: float = 0.0

var current_target: Node2D = null
var _target_locked: bool = false

var sprite: Sprite2D
var trail_points: Array = []
var trail_max_length: int = 8
var _trail_draw_skip: int = 0

var _frame_counter: int = 0

func _ready() -> void:
	sprite = $Sprite2D
	body_entered.connect(_on_body_entered)
	_bullet_counter += 1
	_enforce_bullet_limit()

func _enforce_bullet_limit() -> void:
	if not game_manager or not is_instance_valid(game_manager):
		return
	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return
	while bullet_root.get_child_count() > MAX_BULLETS:
		var oldest = bullet_root.get_child(0)
		if is_instance_valid(oldest):
			oldest.queue_free()
		else:
			break

func _physics_process(delta: float) -> void:
	_frame_counter += 1

	_fps_check_timer += delta
	if _fps_check_timer >= 1.0:
		_fps_check_timer = 0.0
		_last_fps = Engine.get_frames_per_second()
		if _last_fps < 30.0 and not _low_fps_mode:
			_low_fps_mode = true
			_degrade_all_bullets()
		elif _last_fps >= 45.0 and _low_fps_mode:
			_low_fps_mode = false

	_far_check_counter += 1
	if _far_check_counter >= FAR_CHECK_INTERVAL:
		_far_check_counter = 0
		_check_and_degrade_far_bullets()

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

	var is_mobile = PerformanceSettings.is_mobile if PerformanceSettings else false
	var effective_trail_max = trail_max_length
	if is_mobile:
		effective_trail_max = maxi(3, trail_max_length / 2)

	trail_points.push_front(global_position)
	if trail_points.size() > effective_trail_max:
		trail_points.pop_back()

	_trail_draw_skip += 1
	if _trail_draw_skip >= 2:
		_trail_draw_skip = 0
		queue_redraw()

func _update_target_tracking(delta: float) -> void:
	tracking_time += delta

	if tracking_time > max_tracking_time:
		return

	if not _target_locked:
		current_target = _find_nearest_enemy()
		if current_target:
			target_dir = (current_target.global_position - global_position).normalized()
			_target_locked = true
		return

	if is_instance_valid(current_target):
		if _is_target_alive(current_target):
			target_dir = (current_target.global_position - global_position).normalized()
		else:
			current_target = null

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

func _check_and_degrade_far_bullets() -> void:
	if not game_manager or not is_instance_valid(game_manager):
		return
	if not player or not is_instance_valid(player):
		return
	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return
	for i in range(bullet_root.get_child_count()):
		var bullet = bullet_root.get_child(i)
		if not is_instance_valid(bullet) or bullet == self:
			continue
		if bullet.has_method("apply_far_degradation"):
			var dist = global_position.distance_to(bullet.global_position)
			if dist > FAR_DISTANCE:
				bullet.apply_far_degradation()

func apply_far_degradation() -> void:
	if _far_bullet_degraded:
		return
	_far_bullet_degraded = true
	queue_redraw()

func _degrade_all_bullets() -> void:
	if not game_manager or not is_instance_valid(game_manager):
		return
	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return
	for i in range(bullet_root.get_child_count()):
		var bullet = bullet_root.get_child(i)
		if not is_instance_valid(bullet):
			continue
		if bullet.has_method("apply_far_degradation"):
			bullet.apply_far_degradation()

func _draw() -> void:
	if trail_points.size() < 2:
		return

	var width = 6.0
	var is_mobile = PerformanceSettings.is_mobile if PerformanceSettings else false
	var mobile_max = maxi(3, trail_max_length / 2)
	var points_to_draw = trail_points.size()
	if is_mobile or _low_fps_mode or _far_bullet_degraded:
		points_to_draw = mini(points_to_draw, mobile_max)
	points_to_draw = mini(points_to_draw, trail_points.size())
	for i in range(points_to_draw - 1):
		var alpha = 1.0 - float(i) / float(points_to_draw)
		var color = Color(1.0, 0.6, 0.1, alpha * 0.7)
		var start = trail_points[i] - global_position
		var end = trail_points[i + 1] - global_position
		draw_line(start, end, color, width * alpha, true)

func setup_target_direction(dir: Vector2, dmg: float, spd: float, cr: float, cm: float, gm: Node2D, splash_rad: float = 0.0, splash_cnt: int = 0, range_limit: float = 500.0, p: Node2D = null) -> void:
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
	player = p
	_far_bullet_degraded = false
	_low_fps_mode = false

func setup_with_target(dir: Vector2, dmg: float, spd: float, cr: float, cm: float, gm: Node2D, target: Node2D, splash_rad: float = 0.0, splash_cnt: int = 0, range_limit: float = 500.0) -> void:
	setup_target_direction(dir, dmg, spd, cr, cm, gm, splash_rad, splash_cnt, range_limit)
	current_target = target
	_target_locked = true
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

	var explosion = _SCENE_DEATH_EXPLOSION.instantiate()
	var perf = PerformanceSettings
	if perf and perf.is_mobile:
		explosion.amount = mini(perf.get_explosion_particle_count(30), 15)
	else:
		explosion.amount = 30

	explosion.direction = Vector2(0, -1)
	explosion.spread = 180.0
	explosion.initial_velocity_min = 100.0
	explosion.initial_velocity_max = 200.0
	explosion.scale_amount_min = 4.0
	explosion.scale_amount_max = 8.0
	explosion.color = Color(1.0, 0.5, 0.1, 1.0)
	explosion.gravity = Vector2(0, 200)
	explosion.emission_shape = 1
	explosion.emission_sphere_radius = splash_radius if splash_radius > 0.0 else 40.0

	explosion.global_position = pos
	bullet_root.add_child(explosion)
	explosion.emitting = true
	explosion.finished.connect(explosion.queue_free)
