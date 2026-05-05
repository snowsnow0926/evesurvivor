extends Node2D

var params: Dictionary = {}
var flash_particles: CPUParticles2D
var flash_sprite: Sprite2D
var smoke_particles: CPUParticles2D
var timer: Timer

func _ready() -> void:
	flash_particles = $FlashParticles
	flash_sprite = $FlashSprite
	smoke_particles = $SmokeParticles
	_create_flash_texture()

func _create_flash_texture() -> void:
	var size = 128
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		for x in range(size):
			var center = Vector2(size, size) / 2.0
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			var max_dist = size / 2.0
			if dist < max_dist:
				var intensity = 1.0 - (dist / max_dist)
				intensity = pow(intensity, 1.5)
				var r = 1.0
				var g = 0.7 + intensity * 0.3
				var b = 0.2 + intensity * 0.2
				image.set_pixel(x, y, Color(r, g, b, intensity * 0.9))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	var texture = ImageTexture.create_from_image(image)
	flash_sprite.texture = texture
	flash_sprite.scale = Vector2(0.3, 0.3)

func setup(p: Dictionary) -> void:
	params = p

func _physics_process(delta: float) -> void:
	pass

func fire() -> void:
	if flash_particles:
		flash_particles.emitting = true
	if smoke_particles:
		smoke_particles.emitting = true

	var tween = create_tween()
	if flash_sprite:
		flash_sprite.scale = Vector2(0.3, 0.3)
		flash_sprite.modulate.a = 0.9
		tween.tween_property(flash_sprite, "scale", Vector2(0.8, 0.8), 0.05)
		tween.parallel().tween_property(flash_sprite, "modulate:a", 0.0, 0.1)

	tween.tween_callback(queue_free)
