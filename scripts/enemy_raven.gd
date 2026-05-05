extends EnemyBase

var explosion_range: float = 100.0
var explosion_damage: float = 25.0
var explosion_windup: float = 0.5

var current_state: String = "chase"
var windup_timer: float = 0.0
var windup_flash_timer: float = 0.0
var windup_flash_visible: bool = true

func _ready() -> void:
	super()
	_icon_id = "npcfrigate"
	tonnage = "rookie"
	_base_tint = Color(1.0, 0.6, 0.0)
	_visual_scale = 0.85
	_death_particle_color = Color(1.0, 0.5, 0.0, 1.0)
	set_enemy_icon()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func _process_combat(_delta: float) -> void:
	pass

func _update_movement(delta: float) -> void:
	var player = _get_player()
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	match current_state:
		"chase":
			var dir = global_position.direction_to(player.global_position).normalized()
			velocity = dir * move_speed
			move_and_slide()
			var dist = global_position.distance_to(player.global_position)
			if dist < 30.0:
				current_state = "windup"
				velocity = Vector2.ZERO
				windup_timer = 0.0
				windup_flash_timer = 0.0
				windup_flash_visible = true
		"windup":
			velocity = Vector2.ZERO
			move_and_slide()
			windup_timer += delta
			windup_flash_timer += delta
			if windup_flash_timer >= 0.1:
				windup_flash_timer = 0.0
				windup_flash_visible = not windup_flash_visible
				queue_redraw()
			if windup_timer >= explosion_windup:
				_do_explosion()

func _do_explosion() -> void:
	SoundManager.play_sfx("enemy_death")
	var player = _get_player()
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= explosion_range:
			if player.has_method("on_player_take_damage"):
				player.on_player_take_damage(explosion_damage)

	_death_particle_color = Color(1.0, 0.4, 0.1, 1.0)
	_death_particle_count = 15
	_death_particle_velocity_min = 100.0
	_death_particle_velocity_max = 200.0
	_death_particle_scale_min = 3.0
	_death_particle_scale_max = 7.0

	var parent = get_parent()
	if parent:
		var explosion = CPUParticles2D.new()
		explosion.amount = 30
		explosion.lifetime = 0.5
		explosion.one_shot = true
		explosion.emission_shape = 0
		explosion.direction = Vector2(0, -1)
		explosion.spread = 180.0
		explosion.initial_velocity_min = 150.0
		explosion.initial_velocity_max = 300.0
		explosion.scale_amount_min = 4.0
		explosion.scale_amount_max = 10.0
		explosion.color = Color(1.0, 0.4, 0.1, 1.0)
		explosion.position = global_position
		parent.call_deferred("add_child", explosion)
		explosion.emitting = true
		explosion.finished.connect(explosion.queue_free)

	queue_free()

func _die() -> void:
	SoundManager.play_sfx("enemy_death")
	enemy_dead.emit(self, "raven")
	if game_manager and is_instance_valid(game_manager):
		game_manager.try_drop_equipment(global_position)
	queue_free()

func _get_enemy_type() -> String:
	return "raven"

func is_windup_blinking() -> bool:
	return current_state == "windup"

func is_windup_state() -> bool:
	return current_state == "windup"

func get_windup_blink_visible() -> bool:
	return windup_flash_visible

func get_locked_bracket_color() -> Color:
	if current_state == "windup":
		return Color(1.0, 0.5, 0.0)
	return Color(1.0, 0.2, 0.2)
