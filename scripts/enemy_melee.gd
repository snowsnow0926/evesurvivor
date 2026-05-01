extends EnemyBase

var attack_cooldown: float = 0.5
var attack_timer: float = 0.0
var can_attack: bool = true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func _process_combat(_delta: float) -> void:
	if not can_attack:
		attack_timer += _delta
		if attack_timer >= attack_cooldown:
			attack_timer = 0.0
			can_attack = true
		return

	var player = _get_player()
	if not is_instance_valid(player):
		return

	var dist = global_position.distance_to(player.global_position)
	if dist < 30.0:
		can_attack = false
		attack_timer = 0.0
		if player.has_method("on_player_take_damage"):
			player.on_player_take_damage(damage)

func _update_movement(_delta: float) -> void:
	var player = _get_player()
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction = global_position.direction_to(player.global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

func _get_enemy_type() -> String:
	return "melee"
