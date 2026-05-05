extends Node2D

var params: Dictionary = {}
var charge_particles: CPUParticles2D
var charge_glow: Sprite2D
var charge_level: float = 0.0
var max_charge_time: float = 0.3
var charge_timer: float = 0.0
var is_charging: bool = false

func _ready() -> void:
	charge_particles = $ChargeParticles
	charge_glow = $ChargeGlow
	_create_glow_texture()
	charge_particles.emitting = false

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
				image.set_pixel(x, y, Color(0.3, 1.0, 0.8, intensity * 0.8))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	var texture = ImageTexture.create_from_image(image)
	charge_glow.texture = texture

func setup(p: Dictionary) -> void:
	params = p
	if p.has("charge_time"):
		max_charge_time = p["charge_time"]

func _physics_process(delta: float) -> void:
	if is_charging:
		charge_timer += delta
		charge_level = min(charge_timer / max_charge_time, 1.0)
		_update_charge_visual()

func _update_charge_visual() -> void:
	if charge_glow:
		charge_glow.modulate.a = charge_level * 0.7
		charge_glow.scale = Vector2(0.5 + charge_level * 0.5, 0.5 + charge_level * 0.5)
	if charge_particles:
		charge_particles.scale_amount_min = 2.0 + charge_level * 4.0
		charge_particles.scale_amount_max = 5.0 + charge_level * 8.0

func start_charge() -> void:
	is_charging = true
	charge_timer = 0.0
	charge_level = 0.0
	charge_particles.emitting = true

func is_charged() -> bool:
	return charge_level >= 1.0

func release() -> void:
	is_charging = false
	charge_particles.emitting = false
	var tween = create_tween()
	if charge_glow:
		tween.tween_property(charge_glow, "modulate:a", 0.0, 0.1)
		tween.parallel().tween_property(charge_glow, "scale", Vector2(2.0, 2.0), 0.1)
		tween.tween_callback(queue_free)
	else:
		queue_free()
