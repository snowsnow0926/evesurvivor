extends CharacterBody2D

var game_manager: Node2D

var max_hp: float = 20.0
var hp: float = 20.0
var damage: float = 10.0
var move_speed: float = 60.0

var fire_interval: float = 1.2
var fire_timer: float = 0.0
var bullet_speed: float = 400.0
var bullet_damage: float = 8.0
var detection_range: float = 700.0
var preferred_distance: float = 350.0
var fire_range: float = 500.0
var contact_cooldown: float = 0.5
var contact_timer: float = 0.0

var polygon: Node2D
var hp_bar: ColorRect
var current_state: String = "idle"

func _ready() -> void:
	polygon = $Polygon2D
	hp_bar = $HPBar
	if polygon:
		polygon.rotation = PI / 2

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

	var dist = global_position.distance_to(player.global_position)

	if dist > detection_range:
		velocity = Vector2.ZERO
		current_state = "idle"
	elif dist < preferred_distance - 20.0:
		var dir = global_position.direction_to(player.global_position).normalized()
		velocity = -dir * move_speed
		current_state = "retreat"
	elif dist > preferred_distance + 20.0:
		var dir = global_position.direction_to(player.global_position).normalized()
		velocity = dir * move_speed
		current_state = "approach"
	else:
		velocity = Vector2.ZERO
		current_state = "hold"

	move_and_slide()

	contact_timer += delta
	if contact_timer >= contact_cooldown:
		contact_timer = 0.0
		if dist < 30.0:
			if player.has_method("on_player_take_damage"):
				player.on_player_take_damage(damage)

	if current_state != "idle" and dist <= fire_range:
		fire_timer += delta
		if fire_timer >= fire_interval:
			fire_timer = 0.0
			_fire_at_player()

func _fire_at_player() -> void:
	if not game_manager:
		return
	var player = game_manager.get("player")
	if not is_instance_valid(player):
		return
	if global_position.distance_to(player.global_position) > fire_range:
		return

	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return

	var bullet_path = "res://scenes/SentryBullet.tscn"
	if not ResourceLoader.exists(bullet_path):
		return

	var bullet_scene = load(bullet_path)
	var bullet = bullet_scene.instantiate()
	bullet_root.add_child(bullet)
	bullet.global_position = global_position

	var dir = global_position.direction_to(player.global_position).normalized()
	bullet.setup(dir, bullet_damage, bullet_speed, game_manager, player)

func setup_enemy(gm: Node2D, e_hp: float, e_damage: float, e_speed: float) -> void:
	game_manager = gm
	max_hp = e_hp
	hp = e_hp
	damage = e_damage
	move_speed = e_speed

func take_damage(amount: float, is_crit: bool = false) -> void:
	SoundManager.play_sfx("hit")
	hp -= amount

	_spawn_damage_number(amount, is_crit)

	if hp_bar:
		hp_bar.scale.x = clamp(hp / max_hp, 0.0, 1.0)
		hp_bar.position.x = -17.0 * clamp(hp / max_hp, 0.0, 1.0)

	_start_hit_flash()

	if hp <= 0:
		_die()

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
	parent.add_child(label)

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

func _start_hit_flash() -> void:
	if polygon:
		var original_color = polygon.modulate
		polygon.modulate = Color(2.0, 2.0, 2.0)
		var tween = create_tween()
		tween.tween_property(polygon, "modulate", original_color, 0.15)

func _die() -> void:
	SoundManager.play_sfx("enemy_death")
	if current_state == "windup":
		return
	if game_manager and is_instance_valid(game_manager):
		game_manager.on_enemy_killed(self, "sentry")
	_spawn_death_effect()
	queue_free()

func _spawn_death_effect() -> void:
	var parent = get_parent()
	if not parent:
		return
	var particles = CPUParticles2D.new()
	particles.amount = 12
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.emission_shape = 0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 150.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	particles.color = Color(0.6, 0.3, 1.0, 1.0)
	particles.position = global_position

	parent.call_deferred("add_child", particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)
