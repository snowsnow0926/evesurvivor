extends Area2D

var game_manager: Node2D
var lifetime: float = 0.0
var max_lifetime: float = 30.0
var xp_amount: float = 1.0
var float_amplitude: float = 3.0
var base_y: float = 0.0
var base_x: float = 0.0

var attracted: bool = false
var attract_speed: float = 400.0
var float_tween: Tween

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sparkle: CPUParticles2D = $SparkleParticles
@onready var collision: CollisionShape2D = $CollisionShape2D

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

	if attracted and game_manager and is_instance_valid(game_manager):
		var player = game_manager.get("player")
		if player and is_instance_valid(player):
			var dir = player.global_position - global_position
			var dist = dir.length()
			if dist < 20:
				game_manager.on_exp_orb_collected(xp_amount)
				queue_free()
				return
			dir = dir.normalized()
			position += dir * attract_speed * delta
			attract_speed += 200 * delta

func set_game_manager(gm: Node2D) -> void:
	game_manager = gm

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" and is_instance_valid(game_manager):
		attracted = true
		if float_tween:
			float_tween.kill()
		if anim_sprite:
			anim_sprite.speed_scale = 3.0
		if sparkle:
			sparkle.speed_scale = 2.5
		var scale_tween = create_tween()
		scale_tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.1)
