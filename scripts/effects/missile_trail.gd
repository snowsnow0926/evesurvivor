extends Node2D

var params: Dictionary = {}
var trail_particles: CPUParticles2D
var smoke_particles: CPUParticles2D
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.0
var max_lifetime: float = 3.0

func _ready() -> void:
	trail_particles = $TrailParticles
	smoke_particles = $SmokeParticles

func setup(p: Dictionary) -> void:
	params = p
	if p.has("direction"):
		direction = p["direction"].normalized()
		rotation = direction.angle()
		if trail_particles:
			trail_particles.direction = -direction
			trail_particles.rotation = direction.angle()
		if smoke_particles:
			smoke_particles.direction = -direction
			smoke_particles.rotation = direction.angle()
	if p.has("lifetime"):
		max_lifetime = p["lifetime"]

func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime >= max_lifetime:
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)
		set_physics_process(false)
		return

	if trail_particles:
		trail_particles.emitting = true
	if smoke_particles and randf() < 0.3:
		smoke_particles.emitting = true

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()
	if trail_particles:
		trail_particles.direction = -direction
		trail_particles.rotation = direction.angle()
	if smoke_particles:
		smoke_particles.direction = -direction
		smoke_particles.rotation = direction.angle()
