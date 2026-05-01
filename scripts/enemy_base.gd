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

# === Shared Nodes ===
var polygon: Node2D
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
	hp_bar = $HPBar
	if polygon:
		polygon.rotation = PI / 2

func _physics_process(delta: float) -> void:
	if not is_instance_valid(game_manager) or game_manager.is_game_over or game_manager.is_paused:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_update_movement(delta)
	_process_combat(delta)

func _process_combat(_delta: float) -> void:
	pass

func _update_movement(_delta: float) -> void:
	pass

func _get_player() -> Node:
	if not is_instance_valid(game_manager):
		return null
	return game_manager.get("player")

func setup_enemy(gm: Node2D, e_hp: float, e_damage: float, e_speed: float) -> void:
	game_manager = gm
	max_hp = e_hp
	hp = e_hp
	damage = e_damage
	move_speed = e_speed

func take_damage(amount: float, is_crit: bool = false) -> void:
	if hp <= 0:
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

func _start_hit_flash() -> void:
	if polygon:
		var original_color = polygon.modulate if not polygon.modulate is Color else polygon.modulate
		polygon.modulate = Color(2.0, 2.0, 2.0)
		var tween = create_tween()
		tween.tween_property(polygon, "modulate", original_color, 0.15)

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

func _die() -> void:
	SoundManager.play_sfx("enemy_death")
	enemy_dead.emit(self, _get_enemy_type())
	_spawn_death_effect()
	queue_free()

func _get_enemy_type() -> String:
	return "melee"
