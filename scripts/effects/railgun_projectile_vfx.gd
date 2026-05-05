extends Node2D

var params: Dictionary = {}
var speed: float = 1000.0
var direction: Vector2 = Vector2.RIGHT
var traveled_distance: float = 0.0
var max_range: float = 400.0
var trail_points: Array = []
var trail_max_length: int = 15
var lifetime: float = 0.0
var max_lifetime: float = 2.0

var core_line: Line2D
var arc_particles: CPUParticles2D
var trail_line: Line2D

func _ready() -> void:
	core_line = $CoreLine
	arc_particles = $ArcParticles
	trail_line = $TrailLine
	arc_particles.emitting = true

func setup(p: Dictionary) -> void:
	params = p
	if p.has("speed"):
		speed = p["speed"]
	if p.has("direction"):
		direction = p["direction"].normalized()
	if p.has("range"):
		max_range = p["range"]

func _physics_process(delta: float) -> void:
	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()
		return

	var move_step = direction * speed * delta
	global_position += move_step
	traveled_distance += move_step.length()

	if traveled_distance >= max_range:
		_spawn_discharge_effect()
		queue_free()
		return

	rotation = direction.angle()
	_update_electric_arc()
	_update_trail()

func _update_electric_arc() -> void:
	if not core_line:
		return

	var start = Vector2.ZERO
	var arc_points = [start]

	var arc_length = randf_range(20.0, 40.0)
	var num_segments = randi_range(3, 5)
	for i in range(num_segments):
		var t = float(i + 1) / float(num_segments)
		var along = start + direction * arc_length * t
		var perp = direction.rotated(PI / 2.0)
		var offset = randf_range(-15.0, 15.0) if i > 0 and i < num_segments - 1 else 0.0
		arc_points.append(along + perp * offset)

	arc_points.append(start + direction * arc_length)

	core_line.clear_points()
	for pt in arc_points:
		core_line.add_point(pt)

	if arc_particles:
		arc_particles.direction = -direction
		arc_particles.rotation = direction.angle()

func _update_trail() -> void:
	trail_points.push_front(global_position)
	if trail_points.size() > trail_max_length:
		trail_points.pop_back()

	if not trail_line:
		return

	trail_line.clear_points()
	for pt in trail_points:
		trail_line.add_point(pt - global_position)

func _spawn_discharge_effect() -> void:
	var discharge = Node2D.new()
	discharge.global_position = global_position
	var particles = CPUParticles2D.new()
	particles.amount = 25
	particles.lifetime = 0.3
	particles.explosiveness = 0.8
	particles.emission_shape = 1
	particles.emission_sphere_radius = 15.0
	particles.spread = 180.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 150.0
	particles.color = Color(0.3, 1.0, 0.8, 0.9)
	particles.one_shot = true
	discharge.add_child(particles)
	get_parent().add_child(discharge)
	particles.emitting = true

	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.timeout.connect(particles.queue_free)
	timer.timeout.connect(discharge.queue_free)
	timer.timeout.connect(timer.queue_free)
	discharge.add_child(timer)
	timer.start()
