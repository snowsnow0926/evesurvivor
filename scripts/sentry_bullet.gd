extends Area2D

var target_pos: Vector2 = Vector2.ZERO
var damage: float = 8.0
var speed: float = 400.0
var game_manager: Node2D
var player_ref: Node = null
var lifetime: float = 0.0
var max_lifetime: float = 3.0
var has_hit: bool = false

const PLAYER_RADIUS: float = 16.0
const BULLET_RADIUS: float = 6.0

func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime > max_lifetime:
		queue_free()
		return

	position += target_pos * speed * delta

	if has_hit:
		return

	var player = player_ref
	if not is_instance_valid(player):
		player = game_manager.get("player") if game_manager else null
	if not is_instance_valid(player):
		return

	var dist = global_position.distance_to(player.global_position)
	if dist < PLAYER_RADIUS + BULLET_RADIUS:
		has_hit = true
		if player.has_method("on_player_take_damage"):
			player.on_player_take_damage(damage)
		queue_free()

func setup(dir: Vector2, dmg: float, spd: float, gm: Node2D, p: Node = null) -> void:
	target_pos = dir.normalized()
	damage = dmg
	speed = spd
	game_manager = gm
	player_ref = p
