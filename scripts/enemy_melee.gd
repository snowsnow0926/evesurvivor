extends CharacterBody2D

var game_manager: Node2D

var max_hp: float = 30.0
var hp: float = 30.0
var damage: float = 10.0
var move_speed: float = 100.0

var attack_cooldown: float = 0.5
var attack_timer: float = 0.0
var can_attack: bool = true

var polygon: Node2D
var hp_bar: ColorRect

func _ready() -> void:
	polygon = $Polygon2D
	hp_bar = $HPBar
	print("[EnemyMelee] _ready, polygon=", polygon)
	if polygon:
		polygon.rotation = PI / 2

func _physics_process(delta: float) -> void:
	if not game_manager or game_manager.is_game_over or game_manager.is_paused:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_update_movement(delta)
	_update_contact_damage(delta)

func _update_movement(delta: float) -> void:
	if not game_manager:
		return
	var player = game_manager.get("player")
	if not is_instance_valid(player):
		return

	var direction = global_position.direction_to(player.global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

func _update_contact_damage(delta: float) -> void:
	if not can_attack:
		attack_timer += delta
		if attack_timer >= attack_cooldown:
			attack_timer = 0.0
			can_attack = true
		return

	var player = game_manager.get("player")
	if not is_instance_valid(player):
		return

	var dist = global_position.distance_to(player.global_position)
	if dist < 30.0:
		can_attack = false
		attack_timer = 0.0
		if player.has_method("on_player_take_damage"):
			player.on_player_take_damage(damage)

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
	if game_manager and is_instance_valid(game_manager):
		game_manager.on_enemy_killed(self, "melee")
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
	particles.color = Color(1.0, 0.3, 0.1, 1.0)
	particles.position = global_position

	parent.call_deferred("add_child", particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)
