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

# === Chapter Tonnage Override ===
var _chapter_icon_override: String = ""
var _chapter_id_override: int = 0

# === Icon ===
const ShipIconGenerator = preload("res://scripts/ship_icon_generator.gd")
const TintShader = preload("res://shaders/ship_tint.gdshader")

const _CHAPTER_ICON_MAP: Dictionary = {
	"melee": {
		2: "enemy_melee_cruiser",
		3: "enemy_melee_battlecruiser",
		4: "enemy_melee_battleship",
		5: "enemy_melee_dreadnought",
	},
	"sentry": {
		2: "enemy_sentry_cruiser",
		3: "enemy_sentry_battlecruiser",
		4: "enemy_sentry_battleship",
		5: "enemy_sentry_dreadnought",
	},
	"raven": {
		2: "enemy_raven_cruiser",
		3: "enemy_raven_battlecruiser",
		4: "enemy_raven_battleship",
		5: "enemy_raven_dreadnought",
	},
}

var _chapter_stats_key: String = "melee"
var _icon_id: String = "enemy_melee"
var _current_angle: float = 0.0
var _turn_speed: float = 4.0
var _icon_tex: Texture2D
var _tint_mat: ShaderMaterial

# === Visual Identity (subclasses override) ===
var _visual_scale: float = 0.3
var _tint_mult: float = 1.0
var _base_tint: Color = Color(1.0, 0.3, 0.3)
var _stage_visual_level: int = 0

# === Lock State ===
enum LockState { LOCKING, FLASHING, LOCKED }
const LOCK_DURATION: float = 1.0
const FLASH_INTERVAL: float = 0.25
const FLASH_COUNT: int = 3
const ATTACK_FLASH_INTERVAL: float = 1.5
var _lock_state: LockState = LockState.LOCKING
var _lock_timer: float = 0.0
var _flash_timer: float = 0.0
var _flash_count: int = 0
var _flash_visible: bool = true
var _attack_flash_timer: float = 0.0
var _attack_flash_cooldown: float = 0.0
var _is_locked: bool = false

# === Shared Nodes ===
var ship_sprite: Sprite2D
var hp_bar: ColorRect

# === Shield ===
var enemy_shield: float = 0.0
var enemy_shield_max: float = 0.0
var enemy_shield_regen: float = 0.0
var enemy_shield_regen_timer: float = 0.0
var shield_bar: ColorRect

# === Death Effect Config (override in subclasses) ===
var _death_particle_color: Color = Color(1.0, 0.3, 0.1, 1.0)
var _death_particle_count: int = 12
var _death_particle_lifetime: float = 0.4
var _death_particle_velocity_min: float = 80.0
var _death_particle_velocity_max: float = 150.0
var _death_particle_scale_min: float = 2.0
var _death_particle_scale_max: float = 5.0

# === Damage Number Config (override in subclasses) ===
var _dmg_number_font_size_normal: int = 14
var _dmg_number_font_size_crit: int = 20
var _dmg_number_offset_x_range: float = 20.0
var _dmg_number_offset_y: float = -30.0
var _dmg_number_anim_offset: float = 50.0
var _dmg_number_anim_duration: float = 0.6
var _dmg_number_color_normal: Color = Color(1.0, 1.0, 1.0)
var _dmg_number_color_crit: Color = Color(1.0, 0.8, 0.0)

# === Hit Flash Config (override in subclasses) ===
var _hit_flash_intensity: float = 2.0

# === HP Bar Config (override in subclasses) ===
var _hp_bar_max_width: float = 34.0
var _death_burst_count: int = 1

var is_elite: bool = false
var elite_glow_color: Color = Color(1.0, 0.8, 0.0, 1.0)

# === Signal ===
signal enemy_dead(enemy: Node2D, enemy_type: String)

func _ready() -> void:
	ship_sprite = $ShipSprite
	hp_bar = $HPBar
	shield_bar = $ShieldBar
	_tint_mat = ShaderMaterial.new()
	_tint_mat.shader = TintShader
	_tint_mat.set_shader_parameter("tint_color", _base_tint)
	_tint_mat.set_shader_parameter("saturation_mult", _tint_mult)
	set_enemy_icon()
	_init_lock()

func set_elite(val: bool) -> void:
	if is_elite == val:
		return
	is_elite = val
	if is_elite:
		_apply_elite_appearance()

func _apply_elite_appearance() -> void:
	_base_tint = elite_glow_color
	_visual_scale = 0.42
	max_hp = int(float(max_hp) * 1.5)
	hp = max_hp
	damage *= 1.5
	move_speed *= 0.8

func _physics_process(delta: float) -> void:
	_update_enemy_shield_regen(delta)
	_update_sprite_visibility()
	if not is_instance_valid(game_manager) or game_manager.is_game_over or game_manager.is_paused:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_update_lock(delta)
	if _lock_state == LockState.LOCKED:
		_update_movement(delta)
		_process_combat(delta)
	_update_rotation(delta)

func _update_sprite_visibility() -> void:
	if ship_sprite == null:
		return
	var show := not is_windup_blinking() or get_windup_blink_visible()
	if ship_sprite.visible != show:
		ship_sprite.visible = show
		queue_redraw()

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

func setup_enemy(gm: Node2D, e_hp: float, e_damage: float, e_speed: float, e_shield: float = 0.0, e_shield_regen: float = 0.0, visual_level: int = 0, chapter_tonnage: String = "", chapter_icon: String = "", chapter_id_override: int = 0, p_is_elite: bool = false) -> void:
	game_manager = gm
	max_hp = e_hp
	hp = e_hp
	damage = e_damage
	move_speed = e_speed
	enemy_shield_max = e_shield
	enemy_shield = e_shield
	enemy_shield_regen = e_shield_regen
	enemy_shield_regen_timer = 0.0
	_chapter_icon_override = chapter_icon
	_chapter_id_override = chapter_id_override
	_apply_chapter_stats()
	_apply_chapter_icon()
	_apply_stage_visual(visual_level)
	if p_is_elite:
		set_elite(true)

func _apply_stage_visual(level: int) -> void:
	_stage_visual_level = level
	_visual_scale = 0.3 + (level - 1) * 0.05
	_tint_mult = 0.6 + (level - 1) * 0.12
	var extra := (level - 1) * 2
	_death_particle_count = maxf(_death_particle_count, 12) + extra
	_death_particle_velocity_min = 80.0 + extra * 10.0
	_death_particle_velocity_max = 150.0 + extra * 15.0
	_death_particle_scale_max = 5.0 + extra * 1.0
	_update_shader_params()

func _apply_chapter_stats() -> void:
	pass

func _apply_chapter_icon() -> void:
	var cid: int = _chapter_id_override if _chapter_id_override > 0 else (game_manager.current_chapter_id if game_manager else 0)

	# override path — used by subclasses for special icons
	if not _chapter_icon_override.is_empty():
		var entry: ShipIconGenerator.IconEntry = ShipIconGenerator.get_entry(ShipIconGenerator.Category.ENEMY, _chapter_icon_override)
		if entry == null:
			return
		_icon_tex = entry.get_texture()
		if ship_sprite != null:
			ship_sprite.texture = _icon_tex
			ship_sprite.material = null
			ship_sprite.visible = true
		return

	# map path — look up icon by chapter and enemy type
	var icon_map: Dictionary = _CHAPTER_ICON_MAP.get(_chapter_stats_key, {})
	var icon_id: String = icon_map.get(cid, "")
	if icon_id.is_empty():
		return

	var entry: ShipIconGenerator.IconEntry = ShipIconGenerator.get_entry(ShipIconGenerator.Category.ENEMY, icon_id)
	if entry == null:
		return
	_icon_tex = entry.get_texture()
	if ship_sprite != null:
		ship_sprite.texture = _icon_tex
		ship_sprite.material = null
		ship_sprite.visible = true

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

func is_windup_blinking() -> bool:
	return false

func get_windup_blink_visible() -> bool:
	return true

func get_locked_bracket_color() -> Color:
	return Color(1.0, 0.2, 0.2)

func is_windup_state() -> bool:
	return false

func set_enemy_icon() -> void:
	var entry: ShipIconGenerator.IconEntry = ShipIconGenerator.get_entry(ShipIconGenerator.Category.ENEMY, _icon_id)
	if entry == null:
		return
	_icon_tex = entry.get_texture()
	if ship_sprite != null:
		ship_sprite.texture = _icon_tex
		ship_sprite.material = null
		ship_sprite.visible = true
	_update_shader_params()

func _update_shader_params() -> void:
	if _tint_mat == null:
		return
	_tint_mat.set_shader_parameter("tint_color", _base_tint)
	_tint_mat.set_shader_parameter("saturation_mult", _tint_mult)
	if ship_sprite != null:
		ship_sprite.scale = Vector2.ONE * _visual_scale

func set_icon_rotation(angle: float) -> void:
	_current_angle = angle
	if ship_sprite != null:
		ship_sprite.rotation = angle + PI / 2
	queue_redraw()

func take_damage(amount: float, is_crit: bool = false) -> void:
	if hp <= 0:
		return
	if _lock_state != LockState.LOCKED:
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
		hp_bar.position.x = -_hp_bar_max_width * 0.5 * ratio

func _spawn_damage_number(amount: float, is_crit: bool) -> void:
	var parent = get_parent()
	if not parent:
		return

	var label = Label.new()
	label.text = str(int(amount)) + ("!" if is_crit else "")
	label.add_theme_font_size_override("font_size", _dmg_number_font_size_crit if is_crit else _dmg_number_font_size_normal)
	if is_crit:
		label.add_theme_color_override("font_color", _dmg_number_color_crit)
	else:
		label.add_theme_color_override("font_color", _dmg_number_color_normal)

	label.position = global_position + Vector2(randf_range(-_dmg_number_offset_x_range, _dmg_number_offset_x_range), _dmg_number_offset_y)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.call_deferred("add_child", label)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - _dmg_number_anim_offset, _dmg_number_anim_duration)
	tween.tween_property(label, "modulate:a", 0.0, _dmg_number_anim_duration)

	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = _dmg_number_anim_duration + 0.1
	timer.timeout.connect(label.queue_free)
	parent.call_deferred("add_child", timer)
	timer.call_deferred("start")

func _spawn_death_effect() -> void:
	var parent = get_parent()
	if not parent:
		return

	var burst_count := maxf(_death_burst_count, 1)
	for _i in range(burst_count):
		var offset := Vector2.ZERO
		if burst_count > 1:
			offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
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
		particles.position = global_position + offset

		parent.call_deferred("add_child", particles)
		particles.emitting = true
		particles.finished.connect(particles.queue_free)

func _start_hit_flash() -> void:
	if not ship_sprite:
		return
	var original_color = ship_sprite.modulate if ship_sprite.modulate is Color else Color.WHITE
	ship_sprite.modulate = Color(_hit_flash_intensity, _hit_flash_intensity, _hit_flash_intensity)
	var tween = create_tween()
	tween.tween_property(ship_sprite, "modulate", original_color, 0.15)

func _die() -> void:
	SoundManager.play_sfx("enemy_death")
	enemy_dead.emit(self, _get_enemy_type())
	_spawn_death_effect()
	_on_death_rewards()
	if game_manager and is_instance_valid(game_manager):
		game_manager.try_drop_equipment(self)
	queue_free()

func _on_death_rewards() -> void:
	pass

func _get_enemy_type() -> String:
	return "melee"

func _get_loot_tonnage_chapter() -> int:
	if _chapter_id_override > 0:
		return _chapter_id_override
	if game_manager != null and is_instance_valid(game_manager):
		return game_manager.current_chapter_id
	return 1

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
	var tex_size: Vector2 = _icon_tex.get_size() if _icon_tex != null else Vector2(ShipIconGenerator.ICON_SIZE, ShipIconGenerator.ICON_SIZE)
	var half_w := tex_size.x * 0.5 * _visual_scale
	var half_h := tex_size.y * 0.5 * _visual_scale

	draw_set_transform(Vector2.ZERO, _current_angle + PI / 2, Vector2.ONE)

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
