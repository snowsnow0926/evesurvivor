extends Area2D

var target_pos: Vector2 = Vector2.ZERO
var damage: float = 10.0
var speed: float = 400.0
var game_manager: Node2D
var player_ref: Node = null
var lifetime: float = 0.0
var max_lifetime: float = 3.0
var has_hit: bool = false

var _low_fps_mode: bool = false
var _fps_check_timer: float = 0.0

const PLAYER_RADIUS: float = 32.0
const BULLET_RADIUS: float = 8.0

@onready var sprite: Sprite2D = $Sprite2D

func _physics_process(delta: float) -> void:
	_fps_check_timer += delta
	if _fps_check_timer >= 1.0:
		_fps_check_timer = 0.0
		var fps = Engine.get_frames_per_second()
		if fps < 30.0 and not _low_fps_mode:
			_low_fps_mode = true
		elif fps >= 45.0 and _low_fps_mode:
			_low_fps_mode = false

	lifetime += delta
	if lifetime > max_lifetime:
		queue_free()
		return

	var speed_mult = 1.0
	if _low_fps_mode or (PerformanceSettings and PerformanceSettings.is_mobile):
		speed_mult = 1.3

	position += target_pos * speed * speed_mult * delta

	if sprite and target_pos != Vector2.ZERO:
		sprite.rotation = target_pos.angle()

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
