extends Area2D

const DEBUG := false

var game_manager: Node2D
var lifetime: float = 0.0
var max_lifetime: float = 30.0
var xp_amount: float = 1.0
var float_amplitude: float = 3.0
var base_y: float = 0.0
var base_x: float = 0.0

var attracted: bool = false
var attract_speed: float = 600.0
var float_tween: Tween

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sparkle: CPUParticles2D = $SparkleParticles
@onready var collision: CollisionShape2D = $CollisionShape2D

const ATTRACT_RANGE: float = 100.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	base_y = position.y
	base_x = position.x
	_start_float_animation()

func _start_float_animation() -> void:
	float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(self, "position", Vector2(base_x, base_y - float_amplitude), 0.5)
	float_tween.tween_property(self, "position", Vector2(base_x, base_y + float_amplitude), 0.5)

func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime > max_lifetime:
		queue_free()
		return

	if not attracted:
		_check_passive_attract()

	if attracted and game_manager and is_instance_valid(game_manager):
		var player = game_manager.get("player")
		if player and is_instance_valid(player):
			var to_player: Vector2 = player.global_position - global_position
			var dist: float = to_player.length()
			if dist < 20:
				game_manager.on_exp_orb_collected(xp_amount)
				queue_free()
				return
			var dir: Vector2 = to_player.normalized()
			global_position += dir * attract_speed * delta
			attract_speed += 400 * delta

func set_game_manager(gm: Node2D) -> void:
	game_manager = gm

func _check_passive_attract() -> void:
	if not game_manager or not is_instance_valid(game_manager):
		return
	var player = game_manager.get("player")
	if not player or not is_instance_valid(player):
		return
	var dist: float = global_position.distance_to(player.global_position)
	if DEBUG:
		print("[ExpOrb] dist=%.1f range=%.1f" % [dist, ATTRACT_RANGE])
	if dist <= ATTRACT_RANGE:
		if DEBUG:
			print("[ExpOrb] PASSIVE ATTRACT TRIGGERED! dist=%.1f" % dist)
		attracted = true
		if float_tween:
			float_tween.kill()
		if anim_sprite:
			anim_sprite.speed_scale = 3.0
		if sparkle:
			sparkle.speed_scale = 2.5
		var scale_tween = create_tween()
		scale_tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.1)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" and is_instance_valid(game_manager) and not attracted:
		if DEBUG:
			print("[ExpOrb] BODY ENTERED TRIGGERED")
		attracted = true
		if float_tween:
			float_tween.kill()
		if anim_sprite:
			anim_sprite.speed_scale = 3.0
		if sparkle:
			sparkle.speed_scale = 2.5
		var scale_tween = create_tween()
		scale_tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.1)
