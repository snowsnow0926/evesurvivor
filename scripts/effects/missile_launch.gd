extends Node2D

var params: Dictionary = {}
var launch_flame: CPUParticles2D
var smoke_trail: CPUParticles2D
var glow_sprite: Sprite2D
var lifetime: float = 0.0
var max_lifetime: float = 0.5
var is_launching: bool = false

func _ready() -> void:
	launch_flame = $LaunchFlame
	smoke_trail = $SmokeTrail
	glow_sprite = $GlowSprite
	_create_glow_texture()

func _create_glow_texture() -> void:
	var size = 64
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		for x in range(size):
			var center = Vector2(size, size) / 2.0
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			var max_dist = size / 2.0
			if dist < max_dist:
				var intensity = 1.0 - (dist / max_dist)
				intensity = pow(intensity, 2.0)
				image.set_pixel(x, y, Color(1.0, 0.5, 0.1, intensity * 0.8))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	var texture = ImageTexture.create_from_image(image)
	glow_sprite.texture = texture

func setup(p: Dictionary) -> void:
	params = p
	if p.has("direction"):
		var dir = p["direction"].normalized()
		rotation = dir.angle()
		if launch_flame:
			launch_flame.rotation = dir.angle()
			launch_flame.direction = -dir
		if smoke_trail:
			smoke_trail.rotation = dir.angle()
			smoke_trail.direction = -dir

func start_launch() -> void:
	is_launching = true
	if launch_flame:
		launch_flame.emitting = true
	if smoke_trail:
		smoke_trail.emitting = true

	var tween = create_tween()
	if glow_sprite:
		glow_sprite.modulate.a = 0.7
		glow_sprite.scale = Vector2(0.4, 0.4)
		tween.tween_property(glow_sprite, "modulate:a", 0.0, 0.3)
		tween.parallel().tween_property(glow_sprite, "scale", Vector2(1.0, 1.0), 0.3)

func _physics_process(delta: float) -> void:
	if is_launching:
		lifetime += delta
		if lifetime >= max_lifetime:
			queue_free()
