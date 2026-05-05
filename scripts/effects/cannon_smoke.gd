extends Node2D

var params: Dictionary = {}
var smoke_particles: CPUParticles2D
var lifetime: float = 0.0
var max_lifetime: float = 1.0
var smoke_timer: float = 0.0

func _ready() -> void:
	smoke_particles = $SmokeParticles

func setup(p: Dictionary) -> void:
	params = p
	if p.has("lifetime"):
		max_lifetime = p["lifetime"]
	if p.has("direction"):
		var dir = p["direction"].normalized()
		smoke_particles.direction = -dir
		smoke_particles.rotation = dir.angle()
	if p.has("smoke_count"):
		smoke_particles.amount = p["smoke_count"]

func _physics_process(delta: float) -> void:
	lifetime += delta
	smoke_timer += delta

	if smoke_timer >= 0.15:
		smoke_timer = 0.0
		if smoke_particles:
			smoke_particles.emitting = true

	if lifetime >= max_lifetime:
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)
		set_physics_process(false)
