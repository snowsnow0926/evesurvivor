extends Node2D

var params: Dictionary = {}

var charge_particles: CPUParticles2D
var glow_sprite: Sprite2D
var timer: Timer

func _ready() -> void:
	charge_particles = $ChargeParticles
	glow_sprite = Sprite2D.new()
	glow_sprite.modulate = Color(0.0, 0.8, 1.0, 0.0)
	add_child(glow_sprite)
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
				image.set_pixel(x, y, Color(0.0, 0.8, 1.0, intensity * 0.8))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	var texture = ImageTexture.create_from_image(image)
	glow_sprite.texture = texture
	glow_sprite.scale = Vector2(0.5, 0.5)

func setup(p: Dictionary) -> void:
	params = p

func _physics_process(delta: float) -> void:
	pass

func start_charge() -> void:
	if charge_particles:
		charge_particles.emitting = true
	var tween = create_tween()
	if glow_sprite:
		glow_sprite.modulate.a = 0.0
		glow_sprite.scale = Vector2(0.3, 0.3)
		tween.tween_property(glow_sprite, "modulate:a", 0.6, 0.15)
		tween.parallel().tween_property(glow_sprite, "scale", Vector2(1.2, 1.2), 0.15)
		tween.tween_property(glow_sprite, "modulate:a", 0.0, 0.1)
		tween.parallel().tween_property(glow_sprite, "scale", Vector2(1.5, 1.5), 0.1)
		tween.tween_callback(queue_free)
