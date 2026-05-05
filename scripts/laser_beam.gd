extends Node2D

var max_range: float = 560.0
var duration: float = 2.0
var tick_interval: float = 0.5
var crit_rate: float = 0.08
var crit_mult: float = 1.6
var beam_width: float = 16.0
var damage_per_tick: float = 12.0
var shield_penetration_mult: float = 1.0

var game_manager: Node2D
var _last_laser_log_time: float = -1.0
var owner_player: Node2D = null
var current_target: Node2D = null
var elapsed: float = 0.0
var tick_timer: float = 0.0
var line2d: Node2D

func _ready() -> void:
	line2d = $Line2D

func _update_target_tracking() -> void:
	# 如果当前目标无效或不在范围内，重新寻找目标
	if not is_instance_valid(current_target):
		current_target = _find_best_target()
		return

	# 检查目标是否仍在射程内
	if is_instance_valid(current_target):
		var dist_to_target = global_position.distance_to(current_target.global_position)
		if dist_to_target > max_range:
			# 目标超出范围，重新寻找射程内最远的目标
			var new_target = _find_best_target()
			if new_target != current_target:
				current_target = new_target
		elif current_target.has_method("is_vulnerable") and not current_target.is_vulnerable():
			current_target = _find_best_target()
	else:
		current_target = _find_best_target()

func _find_best_target() -> Node2D:
	print("[LASER] _find_best_target called. current_target=", current_target)
	# 优先使用当前目标（如果有效）
	if is_instance_valid(current_target):
		if current_target.has_method("is_vulnerable") and not current_target.is_vulnerable():
			print("[LASER] _find_best_target: current invalid (not vulnerable), nulling")
			current_target = null
		else:
			var dist = global_position.distance_to(current_target.global_position)
			if dist <= max_range:
				print("[LASER] _find_best_target: returning current_target (dist=", dist, ")")
				return current_target
		current_target = null

	# 寻找射程内最远的目标
	if not game_manager or not is_instance_valid(game_manager):
		print("[LASER] _find_best_target: no game_manager")
		return null
	var enemy_root = game_manager.get("enemy_root")
	if not enemy_root or not is_instance_valid(enemy_root):
		print("[LASER] _find_best_target: no enemy_root")
		return null

	var farthest: Node2D = null
	var farthest_dist: float = 0.0
	for enemy in enemy_root.get_children():
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		if enemy.has_method("is_vulnerable") and not enemy.is_vulnerable():
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= max_range and dist > farthest_dist:
			farthest_dist = dist
			farthest = enemy
	print("[LASER] _find_best_target: farthest=", farthest, " dist=", farthest_dist)
	return farthest

func _physics_process(delta: float) -> void:
	elapsed += delta
	# 每秒打印一次状态，避免日志溢出
	if elapsed - _last_laser_log_time > 1.0:
		_last_laser_log_time = elapsed
		print("[LASER] _physics_process: is_game_over=", game_manager.is_game_over if game_manager else "no_gm", " elapsed=", elapsed)
	if elapsed >= duration:
		queue_free()
		return

	if is_instance_valid(owner_player):
		global_position = owner_player.global_position

	# 追踪当前目标
	_update_target_tracking()

	# 更新激光视觉效果
	_update_laser_visual()

	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_deal_damage_along_path()

func _update_laser_visual() -> void:
	if not line2d:
		return

	var dist: float

	if is_instance_valid(current_target):
		dist = max_range
		var angle_to_target: float = global_position.angle_to_point(current_target.global_position)
		rotation = angle_to_target
	else:
		line2d.clear_points()
		return

	line2d.clear_points()
	line2d.add_point(Vector2.ZERO)
	line2d.add_point(Vector2(dist, 0))
	line2d.width = beam_width
	line2d.modulate = Color(0.0, 0.6, 1.0, 0.8)
	line2d.z_index = -1

func _deal_damage_along_path() -> void:
	if not game_manager or not is_instance_valid(game_manager):
		print("[LASER] FAIL: no game_manager")
		return
	var enemy_root = game_manager.get("enemy_root")
	if not enemy_root or not is_instance_valid(enemy_root):
		print("[LASER] FAIL: no enemy_root")
		return

	print("[LASER] _deal_damage_along_path called. current_target=", current_target, " enemy_count=", enemy_root.get_child_count())

	var laser_origin = global_position
	var laser_dir: Vector2
	if is_instance_valid(current_target):
		laser_dir = (current_target.global_position - laser_origin).normalized()
	else:
		laser_dir = Vector2.RIGHT
		print("[LASER] WARN: no current_target, using default direction")

	var hit_targets: Array = []

	# 如果有当前目标，优先对目标造成伤害
	if is_instance_valid(current_target):
		if current_target.has_method("is_vulnerable") and not current_target.is_vulnerable():
			print("[LASER] WARN: current_target not vulnerable")
			current_target = null
		else:
			var dist = laser_origin.distance_to(current_target.global_position)
			if dist <= max_range:
				hit_targets.append(current_target)
			else:
				print("[LASER] WARN: current_target out of range dist=", dist)

	# 对路径上的其他敌人造成伤害（激光的AOE效果）
	for child in enemy_root.get_children():
		if not is_instance_valid(child) or not child is Node2D:
			continue
		if child in hit_targets:
			continue
		if child.has_method("is_vulnerable") and not child.is_vulnerable():
			continue
		var dist = laser_origin.distance_to(child.global_position)
		if dist > max_range:
			continue
		var to_target = (child.global_position - laser_origin)
		var angle_diff = absf(laser_dir.angle_to(to_target))
		if angle_diff < 0.15:  # 扩大角度范围，让激光有更好的AOE效果
			hit_targets.append(child)

	print("[LASER] hit_targets count=", hit_targets.size())
	for target in hit_targets:
		var is_crit = randf() < crit_rate
		var dmg = damage_per_tick * (crit_mult if is_crit else 1.0)
		print("[LASER] dealing ", dmg, " to ", target.name, " is_crit=", is_crit)
		if target.has_method("take_laser_damage"):
			target.take_laser_damage(dmg, is_crit, shield_penetration_mult)
		elif target.has_method("take_damage"):
			target.take_damage(dmg, is_crit)

func setup(dir: Vector2, gm: Node2D, weapon: WeaponData = null, initial_target: Node2D = null) -> void:
	game_manager = gm
	elapsed = 0.0
	tick_timer = 0.0
	current_target = initial_target
	if owner_player:
		beam_width = owner_player.laser_width
		duration = owner_player.laser_duration
		shield_penetration_mult = owner_player.laser_shield_penetration_mult
	if weapon != null:
		max_range = weapon.range
		damage_per_tick = weapon.damage
		crit_rate = weapon.crit_rate
		crit_mult = weapon.crit_mult
