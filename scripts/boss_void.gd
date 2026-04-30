extends CharacterBody2D

var game_manager: Node2D

var max_hp: float = 500.0
var hp: float = 500.0
var base_move_speed: float = 80.0
var move_speed: float = 80.0
var collision_damage: float = 15.0
var contact_cooldown: float = 0.5
var contact_timer: float = 0.0

var fire_interval_normal: float = 1.5
var fire_interval_rage: float = 1.0
var fire_timer: float = 0.0
var bullet_speed: float = 400.0
var bullet_damage: float = 10.0
var is_rage: bool = false

var polygon: Node2D
var hp_bar: ColorRect
var hp_bar_bg: ColorRect

func _ready() -> void:
	polygon = $Polygon2D
	hp_bar = $HPBar
	hp_bar_bg = $HPBarBg
	if polygon:
		polygon.rotation = PI / 2
	scale = Vector2(3.0, 3.0)

func _physics_process(delta: float) -> void:
	if not game_manager or game_manager.is_game_over or game_manager.is_paused:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var player = game_manager.get("player")
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dir = global_position.direction_to(player.global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()

	contact_timer += delta
	if contact_timer >= contact_cooldown:
		contact_timer = 0.0
		var player_node = player
		if global_position.distance_to(player_node.global_position) < 50.0:
			if player_node.has_method("on_player_take_damage"):
				player_node.on_player_take_damage(collision_damage)

	if hp / max_hp <= 0.6 and not is_rage:
		_enter_rage_mode()

	fire_timer += delta
	var interval = fire_interval_rage if is_rage else fire_interval_normal
	if fire_timer >= interval:
		fire_timer = 0.0
		_fire_spread()

func _enter_rage_mode() -> void:
	is_rage = true
	move_speed = 120.0
	if polygon:
		polygon.modulate = Color(1.5, 0.3, 0.3)

func _fire_spread() -> void:
	if not game_manager:
		return
	var player = game_manager.get("player")
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
	max_hp = 500.0
	hp = 500.0
	move_speed = base_move_speed
	is_rage = false
	fire_timer = 0.0
	contact_timer = 0.0

func take_damage(amount: float, is_crit: bool = false) -> void:
	SoundManager.play_sfx("hit")
	hp -= amount

	_spawn_damage_number(amount, is_crit)

	if hp_bar:
		hp_bar.scale.x = clamp(hp / max_hp, 0.0, 1.0)
		if hp_bar_bg:
			hp_bar.position.x = -51.0 * clamp(hp / max_hp, 0.0, 1.0)

	_start_hit_flash()

	if hp <= 0:
		_die()

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

func _start_hit_flash() -> void:
	if polygon:
		var original_color = polygon.modulate if not is_rage else Color(1.5, 0.3, 0.3)
		polygon.modulate = Color(3.0, 3.0, 3.0)
		var tween = create_tween()
		tween.tween_property(polygon, "modulate", original_color, 0.15)

func _die() -> void:
	SoundManager.play_sfx("boss_death")
	_spawn_death_effect()
	_spawn_rewards()
	if game_manager and is_instance_valid(game_manager):
		game_manager.on_boss_killed(self)
	queue_free()

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
		particles.color = Color(0.5, 0.0, 0.5, 1.0)
		particles.position = global_position + offset
		parent.call_deferred("add_child", particles)
		particles.emitting = true
		particles.finished.connect(particles.queue_free)

func _spawn_rewards() -> void:
	if not game_manager or not is_instance_valid(game_manager):
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
