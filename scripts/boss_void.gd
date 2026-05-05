extends EnemyBase

var base_move_speed: float = 80.0
var collision_damage: float = 15.0
var contact_cooldown: float = 0.5
var contact_timer: float = 0.0

var fire_interval_normal: float = 1.5
var fire_interval_rage: float = 1.0
var fire_timer: float = 0.0
var bullet_speed: float = 400.0
var bullet_damage: float = 10.0
var is_rage: bool = false
var _boss_shield: float = 0.0
var _boss_shield_max: float = 0.0
var _boss_shield_regen: float = 0.0
var _boss_shield_regen_timer: float = 0.0

var hp_bar_bg: ColorRect

func _ready() -> void:
	super._ready()
	_base_tint = Color(0.5, 0.0, 0.8)
	_visual_scale = 1.5
	_icon_id = "npcfrigate"
	_death_particle_color = Color(0.5, 0.0, 0.5, 1.0)
	set_enemy_icon()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_boss_shield_regen_timer += delta
	if _boss_shield_regen_timer >= 1.0:
		_boss_shield_regen_timer = 0.0
		_boss_shield = minf(_boss_shield + _boss_shield_regen, _boss_shield_max)
		enemy_shield = _boss_shield
		enemy_shield_max = _boss_shield_max
		_update_hp_bar()

func _process_combat(delta: float) -> void:
	var player = _get_player()
	if not is_instance_valid(player):
		return

	contact_timer += delta
	if contact_timer >= contact_cooldown:
		contact_timer = 0.0
		if global_position.distance_to(player.global_position) < 50.0:
			if player.has_method("on_player_take_damage"):
				player.on_player_take_damage(collision_damage)

	if hp / max_hp <= 0.6 and not is_rage:
		_enter_rage_mode()

	fire_timer += delta
	var interval = fire_interval_rage if is_rage else fire_interval_normal
	if fire_timer >= interval:
		fire_timer = 0.0
		_fire_spread()

func take_damage(amount: float, is_crit: bool = false) -> void:
	if hp <= 0:
		return
	if _lock_state != EnemyBase.LockState.LOCKED:
		return
	if _boss_shield_max > 0.0:
		var shield_dmg = minf(_boss_shield, amount)
		_boss_shield -= shield_dmg
		amount -= shield_dmg
		enemy_shield = _boss_shield
		enemy_shield_max = _boss_shield_max
		if _boss_shield <= 0.0:
			_boss_shield = 0.0
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

func take_laser_damage(amount: float, is_crit: bool, shield_penetration_mult: float = 1.0) -> void:
	if hp <= 0:
		return
	if _lock_state != EnemyBase.LockState.LOCKED:
		return
	if _boss_shield_max > 0.0 and _boss_shield > 0.0:
		var effective_amount = amount * shield_penetration_mult
		var actual_shield_dmg = minf(_boss_shield, effective_amount)
		_boss_shield -= actual_shield_dmg
		var hp_dmg = effective_amount - actual_shield_dmg
		if _boss_shield <= 0.0:
			_boss_shield = 0.0
		enemy_shield = _boss_shield
		enemy_shield_max = _boss_shield_max
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

func _enter_rage_mode() -> void:
	is_rage = true
	move_speed = 120.0
	_base_tint = Color(1.0, 0.1, 0.3)
	var locked_tint := _base_tint * 1.8
	_locked_tex = _create_tinted_texture(_icon_tex, locked_tint)
	queue_redraw()

func _fire_spread() -> void:
	var player = _get_player()
	if not is_instance_valid(player):
		return

	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return

	var bullet_path = "res://scenes/BossBullet.tscn"
	if not ResourceLoader.exists(bullet_path):
		return

	var base_angle = global_position.angle_to_point(player.global_position)
	var bullet_count = 5 if is_rage else 3
	var angle_step = deg_to_rad(12.0) if is_rage else deg_to_rad(15.0)
	var total_spread = angle_step * (bullet_count - 1)

	for i in range(bullet_count):
		var angle = base_angle - total_spread / 2.0 + angle_step * i
		var dir = Vector2.from_angle(angle)

		var bullet_scene = load(bullet_path)
		var bullet = bullet_scene.instantiate()
		bullet_root.add_child(bullet)
		bullet.global_position = global_position
		bullet.setup(dir, bullet_damage, bullet_speed, game_manager, player)

func setup_boss(gm: Node2D) -> void:
	game_manager = gm
	max_hp = 500.0 * (gm.enemy_hp / 30.0)
	hp = max_hp
	move_speed = base_move_speed
	is_rage = false
	fire_timer = 0.0
	contact_timer = 0.0
	_boss_shield_max = max_hp * 0.33
	_boss_shield = _boss_shield_max
	_boss_shield_regen = _boss_shield_max * 0.10
	_boss_shield_regen_timer = 0.0
	damage = gm.enemy_damage

func _spawn_damage_number(amount: float, is_crit: bool) -> void:
	var parent = get_parent()
	if not parent:
		return

	var label = Label.new()
	label.text = str(int(amount)) + ("!" if is_crit else "")
	label.add_theme_font_size_override("font_size", 28 if is_crit else 20)
	if is_crit:
		label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	else:
		label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

	label.position = global_position + Vector2(randf_range(-40, 40), -60)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.call_deferred("add_child", label)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 80, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)

	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.9
	timer.timeout.connect(label.queue_free)
	parent.call_deferred("add_child", timer)
	timer.call_deferred("start")

func _update_hp_bar() -> void:
	if hp_bar:
		var ratio = clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)
		hp_bar.scale.x = ratio
		if hp_bar_bg:
			hp_bar.position.x = -51.0 * ratio
	if shield_bar and enemy_shield_max > 0.0:
		var shield_ratio = clampf(enemy_shield / enemy_shield_max, 0.0, 1.0)
		shield_bar.scale.x = shield_ratio
		shield_bar.position.x = -51.0 * shield_ratio

func _start_hit_flash() -> void:
	var target: Node = ship_sprite if ship_sprite and ship_sprite.visible else polygon
	if not target:
		return
	var original_color = target.modulate if target.modulate is Color else Color.WHITE
	target.modulate = Color(3.0, 3.0, 3.0)
	var tween = create_tween()
	tween.tween_property(target, "modulate", original_color, 0.15)

func _spawn_death_effect() -> void:
	var parent = get_parent()
	if not parent:
		return

	for _i in range(5):
		var offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
		var particles = CPUParticles2D.new()
		particles.amount = 40
		particles.lifetime = 1.0
		particles.one_shot = true
		particles.emission_shape = 0
		particles.direction = Vector2(0, -1)
		particles.spread = 180.0
		particles.initial_velocity_min = 100.0
		particles.initial_velocity_max = 300.0
		particles.scale_amount_min = 5.0
		particles.scale_amount_max = 15.0
		particles.color = _death_particle_color
		particles.position = global_position + offset
		parent.call_deferred("add_child", particles)
		particles.emitting = true
		particles.finished.connect(particles.queue_free)

func _spawn_rewards() -> void:
	if not is_instance_valid(game_manager):
		return

	var parent = game_manager.get("exp_orb_root")
	if parent:
		for i in range(10):
			var angle = TAU * i / 10.0
			var orb_scene = load("res://scenes/ExpOrb.tscn")
			if orb_scene:
				var orb = orb_scene.instantiate()
				orb.set_game_manager(game_manager)
				orb.global_position = global_position + Vector2.from_angle(angle) * 60.0
				parent.call_deferred("add_child", orb)

func _die() -> void:
	SoundManager.play_sfx("boss_death")
	_spawn_death_effect()
	_spawn_rewards()
	if game_manager and is_instance_valid(game_manager):
		game_manager.spawn_boss_loot(global_position)
	enemy_dead.emit(self, "boss")
	queue_free()

func _get_enemy_type() -> String:
	return "boss"
