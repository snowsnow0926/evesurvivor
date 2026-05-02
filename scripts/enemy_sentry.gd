extends EnemyBase

var fire_interval: float = 1.2
var fire_timer: float = 0.0
var bullet_speed: float = 400.0
var bullet_damage: float = 8.0
var detection_range: float = 700.0
var preferred_distance: float = 350.0
var fire_range: float = 500.0
var contact_cooldown: float = 0.5
var contact_timer: float = 0.0
var current_state: String = "idle"

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func _process_combat(delta: float) -> void:
	var player = _get_player()
	if not is_instance_valid(player):
		return

	var dist = global_position.distance_to(player.global_position)

	contact_timer += delta
	if contact_timer >= contact_cooldown:
		contact_timer = 0.0
		if dist < 64.0:
			if player.has_method("on_player_take_damage"):
				player.on_player_take_damage(damage)

	if current_state != "idle" and dist <= fire_range:
		fire_timer += delta
		if fire_timer >= fire_interval:
			fire_timer = 0.0
			_fire_at_player()

func _update_movement(_delta: float) -> void:
	var player = _get_player()
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

func _fire_at_player() -> void:
	var player = _get_player()
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

func _die() -> void:
	if current_state == "windup":
		return
	SoundManager.play_sfx("enemy_death")
	enemy_dead.emit(self, "sentry")
	if game_manager and is_instance_valid(game_manager):
		game_manager.try_drop_equipment(global_position)
	queue_free()

func _get_enemy_type() -> String:
	return "sentry"
