extends Node2D

const TICK_INTERVAL: float = 0.1
const BREAK_RANGE_MARGIN: float = 250.0

var max_range: float = 600.0
var break_range: float = 850.0
var dps: float = 28.0
var duration: float = 2.4
var crit_rate: float = 0.10
var crit_mult: float = 1.7
var beam_width: float = 24.0
var damage_to_shield_mult: float = 1.0
var game_manager: Node2D
var owner_player: Node2D = null

var elapsed: float = 0.0
var tick_timer: float = 0.0
var anchor_target: Node2D = null
var _prev_anchor: Node2D = null
var _switch_cooldown: float = 0.0

var line2d_core: Line2D
var line2d_glow: Line2D

var _player_pos: Vector2 = Vector2.ZERO
var _target_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	line2d_core = $Line2D_Core
	line2d_glow = $Line2D_Glow

func _physics_process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return

	_switch_cooldown = maxf(0.0, _switch_cooldown - delta)

	if is_instance_valid(owner_player):
		global_position = owner_player.global_position
		_player_pos = owner_player.global_position

	_update_anchor_target()
	_refresh_laser_visual()

	tick_timer += delta
	if tick_timer >= TICK_INTERVAL:
		tick_timer = 0.0
		_scan_and_damage()

func _update_anchor_target() -> void:
	var farthest = _find_farthest_enemy_in_range()

	if farthest != _prev_anchor:
		if _switch_cooldown <= 0.0:
			anchor_target = farthest
			_prev_anchor = farthest
			_switch_cooldown = 0.05

	if is_instance_valid(anchor_target):
		var dist_to_anchor = _player_pos.distance_to(anchor_target.global_position)
		if dist_to_anchor > break_range:
			anchor_target = null
			_prev_anchor = null
			_switch_cooldown = 0.0

	if is_instance_valid(anchor_target):
		_target_pos = anchor_target.global_position
	else:
		var dir := (_target_pos - _player_pos).normalized() if _target_pos != Vector2.ZERO else Vector2.RIGHT
		_target_pos = _player_pos + dir * max_range

func _scan_and_damage() -> void:
	if not is_instance_valid(game_manager):
		return
	var enemy_root = game_manager.get("enemy_root")
	if not enemy_root or not is_instance_valid(enemy_root):
		return

	var half_w: float = beam_width * 0.5
	var tick_damage: float = dps * TICK_INTERVAL

	for child in enemy_root.get_children():
		if not is_instance_valid(child) or not child is Node2D:
			continue
		if child == self or child == owner_player:
			continue
		if not _is_enemy_in_beam(child.global_position, half_w):
			continue

		var is_crit = randf() < crit_rate
		var dmg = tick_damage * (crit_mult if is_crit else 1.0)

		if child.has_method("take_laser_damage"):
			child.take_laser_damage(dmg, is_crit, damage_to_shield_mult)
		elif child.has_method("take_damage"):
			child.take_damage(dmg, is_crit)

func _is_enemy_in_beam(enemy_pos: Vector2, half_w: float) -> bool:
	var dist = _point_to_segment_distance(enemy_pos, _player_pos, _target_pos)
	return dist <= half_w

func _point_to_segment_distance(point: Vector2, seg_start: Vector2, seg_end: Vector2) -> float:
	var seg_vec: Vector2 = seg_end - seg_start
	var seg_len: float = seg_vec.length()
	if seg_len < 0.0001:
		return point.distance_to(seg_start)

	var t: float = clampf((point - seg_start).dot(seg_vec) / (seg_len * seg_len), 0.0, 1.0)
	var nearest: Vector2 = seg_start + seg_vec * t
	return point.distance_to(nearest)

func _refresh_laser_visual() -> void:
	if not line2d_core or not line2d_glow:
		return

	var to_player := _player_pos - global_position
	var to_target := _target_pos - global_position

	line2d_core.clear_points()
	line2d_core.add_point(to_player)
	line2d_core.add_point(to_target)
	line2d_core.width = beam_width
	line2d_core.default_color = Color(0.6, 0.9, 1.0, 0.95)
	line2d_core.joint_mode = Line2D.LINE_JOINT_ROUND
	line2d_core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line2d_core.end_cap_mode = Line2D.LINE_CAP_ROUND

	line2d_glow.clear_points()
	line2d_glow.add_point(to_player)
	line2d_glow.add_point(to_target)
	line2d_glow.width = beam_width * 3.0
	line2d_glow.default_color = Color(0.0, 0.4, 1.0, 0.25)
	line2d_glow.joint_mode = Line2D.LINE_JOINT_ROUND
	line2d_glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line2d_glow.end_cap_mode = Line2D.LINE_CAP_ROUND

func _find_farthest_enemy_in_range() -> Node2D:
	if not game_manager or not is_instance_valid(game_manager):
		return null
	var enemy_root = game_manager.get("enemy_root")
	if not enemy_root or not is_instance_valid(enemy_root):
		return null

	var farthest: Node2D = null
	var farthest_dist_sq: float = -1.0
	for child in enemy_root.get_children():
		if not is_instance_valid(child) or not child is Node2D:
			continue
		var dist_sq: float = _player_pos.distance_squared_to(child.global_position)
		var dist: float = sqrt(dist_sq)
		if dist <= max_range and dist_sq > farthest_dist_sq:
			farthest_dist_sq = dist_sq
			farthest = child
	return farthest

func setup(dir: Vector2, weapon_dps: float, dur: float, cr: float, cm: float, gm: Node2D, width: float, shield_mult: float = 1.0, player: Node2D = null, rng: float = 600.0) -> void:
	game_manager = gm
	owner_player = player
	dps = weapon_dps
	duration = dur
	crit_rate = cr
	crit_mult = cm
	beam_width = width
	damage_to_shield_mult = shield_mult
	max_range = rng
	break_range = max_range + BREAK_RANGE_MARGIN
	elapsed = 0.0
	tick_timer = 0.0
	anchor_target = null
	_prev_anchor = null
	_switch_cooldown = 0.0

	_player_pos = player.global_position if is_instance_valid(player) else Vector2.ZERO
	_target_pos = _player_pos

	if is_instance_valid(game_manager):
		var enemy_root = game_manager.get("enemy_root")
		if enemy_root and is_instance_valid(enemy_root):
			anchor_target = _find_farthest_enemy_in_range()
			_prev_anchor = anchor_target

	if is_instance_valid(anchor_target):
		_target_pos = anchor_target.global_position
	else:
		_target_pos = _player_pos + dir.normalized() * max_range

	call_deferred("_refresh_laser_visual")
