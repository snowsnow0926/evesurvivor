class_name EnemyBase
extends CharacterBody2D
## Base class for all enemy types. Handles common behavior like
## damage numbers, death effects, hit flash, and HP bar updates.
## Extend this class and override _update_movement() and _process_combat().

# === Shared State ===
var game_manager: Node2D
var max_hp: float = 30.0
var hp: float = 30.0
var damage: float = 10.0
var move_speed: float = 100.0
var tonnage: String = "frigate"
var enemy_shield: float = 0.0
var enemy_shield_max: float = 0.0
var enemy_shield_regen: float = 0.0
var enemy_shield_regen_timer: float = 0.0

var shield_bar: ColorRect

# === Icon ===
const ShipIconGenerator = preload("res://scripts/ship_icon_generator.gd")
var _icon_id: String = "enemy_melee"
var _current_angle: float = 0.0
var _turn_speed: float = 4.0
var _icon_tex: Texture2D
var _locked_tex: Texture2D

# === Lock State ===
enum LockState { LOCKING, FLASHING, LOCKED }
const LOCK_DURATION: float = 0.5
const FLASH_INTERVAL: float = 0.05
const FLASH_COUNT: int = 8
const ATTACK_FLASH_INTERVAL: float = 1.5
var _lock_state: LockState = LockState.LOCKED
var _lock_timer: float = 0.0
var _flash_timer: float = 0.0
var _flash_count: int = 0
var _flash_visible: bool = true
var _attack_flash_timer: float = 0.0
var _attack_flash_cooldown: float = 0.0
var _is_locked: bool = true

# === Visual Identity (subclasses override) ===
var _visual_scale: float = 1.0
var _tint_mult: float = 1.0
var _base_tint: Color = Color(1.0, 0.3, 0.3)
var _stage_visual_level: int = 0

# === Shared Nodes ===
var polygon: Node2D
var ship_sprite: Sprite2D
var hp_bar: ColorRect

# === Death Effect Config (override in subclasses) ===
var _death_particle_color: Color = Color(1.0, 0.3, 0.1, 1.0)
var _death_particle_count: int = 12
var _death_particle_lifetime: float = 0.4
var _death_particle_velocity_min: float = 80.0
var _death_particle_velocity_max: float = 150.0
var _death_particle_scale_min: float = 2.0
var _death_particle_scale_max: float = 5.0

# === Signal ===
signal enemy_dead(enemy: Node2D, enemy_type: String)

func _ready() -> void:
	polygon = $Polygon2D
	ship_sprite = $ShipSprite
	hp_bar = $HPBar
	shield_bar = $ShieldBar
	if polygon:
		polygon.rotation = PI / 2
		polygon.visible = false
	# NOTE: set_enemy_icon() is intentionally NOT called here.
	# Subclasses must set their _icon_id, _base_tint, _visual_scale, etc.
	# BEFORE calling super(), so that when super() runs this base _ready()
	# (GDScript executes super() immediately before subclass body continues),
	# those values are already correct. Then subclasses call set_enemy_icon()
	# at the END of their _ready() — OR they can just call super() first
	# (which no-ops here) and set their values + call set_enemy_icon() after.

func _physics_process(delta: float) -> void:
	_update_lock(delta)
	_update_enemy_shield_regen(delta)
	if not is_instance_valid(game_manager) or game_manager.is_game_over or game_manager.is_paused:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if _lock_state == LockState.LOCKED:
		_update_movement(delta)
		_process_combat(delta)
	_update_rotation(delta)

func _update_enemy_shield_regen(delta: float) -> void:
	if enemy_shield_regen <= 0.0 or enemy_shield_max <= 0.0:
		return
	enemy_shield_regen_timer += delta
	if enemy_shield_regen_timer >= 1.0:
		enemy_shield_regen_timer = 0.0
		enemy_shield = minf(enemy_shield + enemy_shield_regen, enemy_shield_max)
		_update_hp_bar()

func _process_combat(_delta: float) -> void:
	pass

func _update_movement(_delta: float) -> void:
	pass

func _get_player() -> Node:
	if not is_instance_valid(game_manager):
		return null
	return game_manager.get("player")

func setup_enemy(gm: Node2D, e_hp: float, e_damage: float, e_speed: float, e_shield: float = 0.0, e_shield_regen: float = 0.0, visual_level: int = 0) -> void:
	game_manager = gm
	max_hp = e_hp
	hp = e_hp
	damage = e_damage
	move_speed = e_speed
	enemy_shield_max = e_shield
	enemy_shield = e_shield
	enemy_shield_regen = e_shield_regen
	enemy_shield_regen_timer = 0.0
	_apply_stage_visual(visual_level)

func _apply_stage_visual(level: int) -> void:
	_stage_visual_level = level
	# level: 1~6 maps to visual tiers
	# scale: 1.0 at level 1, grows to 1.25 at level 6
	_visual_scale = 1.0 + (level - 1) * 0.05
	# saturation boost: 0.6 at level 1, grows to 1.2 at level 6
	_tint_mult = 0.6 + (level - 1) * 0.12
	# particle count grows with stage level
	var extra := (level - 1) * 2
	_death_particle_count = maxf(_death_particle_count, 12) + extra
	_death_particle_velocity_min = 80.0 + extra * 10.0
	_death_particle_velocity_max = 150.0 + extra * 15.0
	_death_particle_scale_max = 5.0 + extra * 1.0

func _init_lock() -> void:
	_lock_state = LockState.LOCKING
	_lock_timer = 0.0
	_flash_timer = 0.0
	_flash_count = 0
	_flash_visible = true
	_attack_flash_timer = 0.0
	_attack_flash_cooldown = ATTACK_FLASH_INTERVAL
	_is_locked = false
	queue_redraw()

func _update_lock(delta: float) -> void:
	match _lock_state:
		LockState.LOCKING:
			_lock_timer += delta
			queue_redraw()
			if _lock_timer >= LOCK_DURATION:
				_lock_state = LockState.FLASHING
				_flash_timer = 0.0
				_flash_count = 0
				_flash_visible = true
		LockState.FLASHING:
			_flash_timer += delta
			if _flash_timer >= FLASH_INTERVAL:
				_flash_timer = 0.0
				_flash_visible = not _flash_visible
				_flash_count += 1
				queue_redraw()
				if _flash_count >= FLASH_COUNT:
					_lock_state = LockState.LOCKED
					_is_locked = true
					queue_redraw()
		LockState.LOCKED:
			if _attack_flash_timer > 0.0:
				_attack_flash_timer -= delta
				if _attack_flash_timer <= 0.0:
					_attack_flash_timer = 0.0
					_attack_flash_cooldown = ATTACK_FLASH_INTERVAL
					queue_redraw()
			elif _attack_flash_cooldown > 0.0:
				_attack_flash_cooldown -= delta

func trigger_attack_flash() -> void:
	if _lock_state != LockState.LOCKED:
		return
	if _attack_flash_timer <= 0.0 and _attack_flash_cooldown <= 0.0:
		_attack_flash_timer = 0.2
		queue_redraw()

func is_locked() -> bool:
	return _is_locked

func is_vulnerable() -> bool:
	return _lock_state == LockState.LOCKED

func is_windup_blinking() -> bool:
	return false

func get_windup_blink_visible() -> bool:
	return true

func get_locked_bracket_color() -> Color:
	return _base_tint

func is_windup_state() -> bool:
	return false

func set_enemy_icon() -> void:
	var entry: ShipIconGenerator.IconEntry = ShipIconGenerator.get_entry(ShipIconGenerator.Category.ENEMY, _icon_id)
	if entry == null:
		return
	var raw_tex: Texture2D = entry.get_texture()
	if raw_tex == null:
		return
	_icon_tex = raw_tex
	var locked_tint := _base_tint * 1.8
	_locked_tex = _create_tinted_texture(raw_tex, locked_tint)
	if ship_sprite != null:
		ship_sprite.visible = false
	if polygon != null:
		polygon.visible = false

func _create_tinted_texture(source: Texture2D, tint: Color) -> Texture2D:
	# 染色功能已禁用，返回原图
	return source

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

func set_icon_rotation(angle: float) -> void:
	_current_angle = angle
	queue_redraw()

func take_laser_damage(amount: float, is_crit: bool, shield_penetration_mult: float = 1.0) -> void:
	print("[ENEMY] take_laser_damage called: amount=", amount, " is_crit=", is_crit, " lock_state=", _lock_state)
	if hp <= 0:
		return
	if _lock_state != LockState.LOCKED:
		print("[ENEMY] take_laser_damage rejected: not LOCKED")
		return
	if enemy_shield_max > 0.0 and enemy_shield > 0.0:
		var effective_amount = amount * shield_penetration_mult
		var actual_shield_dmg = minf(enemy_shield, effective_amount)
		enemy_shield -= actual_shield_dmg
		var hp_dmg = effective_amount - actual_shield_dmg
		if enemy_shield <= 0.0:
			enemy_shield = 0.0
		_update_hp_bar()
		if hp_dmg <= 0.0:
			return
		amount = hp_dmg
	SoundManager.play_sfx("hit")
	hp -= amount
	_spawn_damage_number(amount, is_crit)
	_update_hp_bar()
	_start_hit_flash()

	if hp <= 0:
		hp = 0
		_die()

func take_damage(amount: float, is_crit: bool = false) -> void:
	if hp <= 0:
		return
	if _lock_state != LockState.LOCKED:
		return
	if enemy_shield_max > 0.0:
		var shield_dmg = minf(enemy_shield, amount)
		enemy_shield -= shield_dmg
		amount -= shield_dmg
		if enemy_shield <= 0.0:
			enemy_shield = 0.0
		_update_hp_bar()
	if amount <= 0:
		return
	SoundManager.play_sfx("hit")
	hp -= amount

	_spawn_damage_number(amount, is_crit)
	_update_hp_bar()
	_start_hit_flash()

	if hp <= 0:
		hp = 0
		_die()

func _update_hp_bar() -> void:
	if hp_bar:
		var ratio = clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)
		hp_bar.scale.x = ratio
		hp_bar.position.x = -17.0 * ratio
	if shield_bar and enemy_shield_max > 0.0:
		var shield_ratio = clampf(enemy_shield / enemy_shield_max, 0.0, 1.0)
		shield_bar.scale.x = shield_ratio
		shield_bar.position.x = -17.0 * shield_ratio

func _spawn_damage_number(amount: float, is_crit: bool) -> void:
	var parent = get_parent()
	if not parent:
		return

	var label = Label.new()
	label.text = str(int(amount)) + ("!" if is_crit else "")
	label.add_theme_font_size_override("font_size", 20 if is_crit else 14)
	if is_crit:
		label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	else:
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

	label.position = global_position + Vector2(randf_range(-20, 20), -30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.call_deferred("add_child", label)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 50, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)

	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.7
	timer.timeout.connect(label.queue_free)
	parent.call_deferred("add_child", timer)
	timer.call_deferred("start")

func _spawn_death_effect() -> void:
	var parent = get_parent()
	if not parent:
		return
	var particles = CPUParticles2D.new()
	particles.amount = _death_particle_count
	particles.lifetime = _death_particle_lifetime
	particles.one_shot = true
	particles.emission_shape = 0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = _death_particle_velocity_min
	particles.initial_velocity_max = _death_particle_velocity_max
	particles.scale_amount_min = _death_particle_scale_min
	particles.scale_amount_max = _death_particle_scale_max
	particles.color = _death_particle_color
	particles.position = global_position

	parent.call_deferred("add_child", particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

func _start_hit_flash() -> void:
	var target: Node = ship_sprite if ship_sprite and ship_sprite.visible else polygon
	if not target:
		return
	var original_color = target.modulate if target.modulate is Color else Color.WHITE
	target.modulate = Color(2.0, 2.0, 2.0)
	var tween = create_tween()
	tween.tween_property(target, "modulate", original_color, 0.15)

func _die() -> void:
	SoundManager.play_sfx("enemy_death")
	enemy_dead.emit(self, _get_enemy_type())
	_spawn_death_effect()
	if game_manager and is_instance_valid(game_manager):
		game_manager.try_drop_equipment(global_position)
	queue_free()

func _get_enemy_type() -> String:
	return "melee"

func _update_rotation(delta: float) -> void:
	var player = _get_player()
	if not is_instance_valid(player):
		return
	var target_angle = global_position.angle_to_point(player.global_position)
	var angle_diff = target_angle - _current_angle
	while angle_diff > PI:
		angle_diff -= 2 * PI
	while angle_diff < -PI:
		angle_diff += 2 * PI
	_current_angle += angle_diff * minf(delta * _turn_speed, 1.0)
	set_icon_rotation(_current_angle)

func _draw() -> void:
	# Raven windup blink: hide entire enemy during "off" frames
	if is_windup_blinking() and not get_windup_blink_visible():
		return

	var tex: Texture2D
	if _lock_state == LockState.LOCKED:
		tex = _locked_tex
	else:
		tex = _icon_tex

	if tex == null:
		return

	var tex_size: Vector2 = tex.get_size()
	var half_w := tex_size.x * 0.5 * _visual_scale
	var half_h := tex_size.y * 0.5 * _visual_scale
	var offset := Vector2(-half_w, -half_h)

	draw_set_transform(Vector2.ZERO, _current_angle + PI / 2, Vector2.ONE * _visual_scale)

	draw_texture(tex, offset)

	# Corner bracket
	var draw_frame: bool = false
	var bracket_color: Color
	var bracket_alpha: float = 1.0

	match _lock_state:
		LockState.LOCKING:
			draw_frame = true
			bracket_color = Color(1.0, 0.85, 0.0)
		LockState.FLASHING:
			draw_frame = _flash_visible
			bracket_color = Color(1.0, 0.85, 0.0)
		LockState.LOCKED:
			bracket_color = get_locked_bracket_color()
			if _attack_flash_timer > 0.0:
				draw_frame = true
				bracket_alpha = 0.3 + 0.7 * (_attack_flash_timer / 0.2)
			else:
				draw_frame = true
				bracket_alpha = 1.0

	if draw_frame:
		var thick := 3.0
		var c := bracket_color
		c.a = bracket_alpha

		# top-left L
		draw_line(Vector2(-half_w, -half_h), Vector2(-half_w + half_w * 0.5, -half_h), c, thick, true)
		draw_line(Vector2(-half_w, -half_h), Vector2(-half_w, -half_h + half_h * 0.5), c, thick, true)

		# top-right L
		draw_line(Vector2(half_w, -half_h), Vector2(half_w - half_w * 0.5, -half_h), c, thick, true)
		draw_line(Vector2(half_w, -half_h), Vector2(half_w, -half_h + half_h * 0.5), c, thick, true)

		# bottom-left L
		draw_line(Vector2(-half_w, half_h), Vector2(-half_w + half_w * 0.5, half_h), c, thick, true)
		draw_line(Vector2(-half_w, half_h), Vector2(-half_w, half_h - half_h * 0.5), c, thick, true)

		# bottom-right L
		draw_line(Vector2(half_w, half_h), Vector2(half_w - half_w * 0.5, half_h), c, thick, true)
		draw_line(Vector2(half_w, half_h), Vector2(half_w, half_h - half_h * 0.5), c, thick, true)
