extends Node2D

var params: Dictionary = {}
var explosion_core: CPUParticles2D
var explosion_outer: CPUParticles2D
var smoke_ring: CPUParticles2D
var shockwave: Line2D
var lifetime: float = 0.0
var max_lifetime: float = 0.8
var explosion_radius: float = 60.0

func _ready() -> void:
	explosion_core = $ExplosionCore
	explosion_outer = $ExplosionOuter
	smoke_ring = $SmokeRing
	shockwave = $Shockwave

func setup(p: Dictionary) -> void:
	params = p
	if p.has("radius"):
		explosion_radius = p["radius"]
		explosion_core.emission_sphere_radius = explosion_radius * 0.4
		explosion_outer.emission_sphere_radius = explosion_radius * 0.6
		smoke_ring.emission_sphere_radius = explosion_radius * 0.2

func start_explosion() -> void:
	explosion_core.emitting = true
	explosion_outer.emitting = true
	smoke_ring.emitting = true

	var tween = create_tween()
	tween.tween_property(shockwave, "visible", true, 0.0)
	tween.tween_callback(_animate_shockwave)

func _animate_shockwave() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(shockwave, "width", explosion_radius * 0.5, 0.2)
	tween.tween_property(shockwave, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): shockwave.visible = false)

func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()

func _draw() -> void:
	shockwave.clear_points()
	var num_points = 32
	for i in range(num_points):
		var angle = TAU * i / num_points
		var pos = Vector2(cos(angle), sin(angle)) * 5.0
		shockwave.add_point(pos)
