extends Node2D

var params: Dictionary = {}
var max_range: float = 700.0
var target: Node2D = null
var owner_pos: Vector2 = Vector2.ZERO
var flicker_timer: float = 0.0
var flicker_interval: float = 0.05
var flicker_amount: float = 0.1

var core_beam: Line2D
var outer_beam: Line2D
var glow_beam: Line2D

func _ready() -> void:
	core_beam = $CoreBeam
	outer_beam = $OuterBeam
	glow_beam = $GlowBeam

func setup(p: Dictionary) -> void:
	params = p
	if p.has("range"):
		max_range = p["range"]
	if p.has("target"):
		target = p["target"]
	if p.has("owner_pos"):
		owner_pos = p["owner_pos"]

func _physics_process(delta: float) -> void:
	flicker_timer += delta
	if flicker_timer >= flicker_interval:
		flicker_timer = 0.0
		_apply_flicker()

	if is_instance_valid(target):
		owner_pos = target.global_position
		if params.has("owner_pos"):
			owner_pos = params["owner_pos"]
	else:
		queue_free()
		return

	var direction = params.get("direction", Vector2.RIGHT)
	global_position = owner_pos
	rotation = direction.angle()
	_update_beam(direction.length())

func _apply_flicker() -> void:
	var random_flicker = randf_range(-flicker_amount, flicker_amount)
	var flicker_scale = 1.0 + random_flicker

	if core_beam:
		core_beam.modulate.a = 0.85 + randf() * 0.15
	if outer_beam:
		outer_beam.width = 14.0 + randf() * 4.0
		outer_beam.modulate.a = 0.3 + randf() * 0.2
	if glow_beam:
		glow_beam.width = 28.0 + randf() * 8.0
		glow_beam.modulate.a = 0.1 + randf() * 0.1

func _update_beam(dir: Vector2) -> void:
	var length = max_range
	if params.has("current_target_dist"):
		length = params["current_target_dist"]
		length = min(length, max_range)

	var start_pos = Vector2.ZERO
	var end_pos = Vector2(length, 0)

	if core_beam:
		core_beam.clear_points()
		core_beam.add_point(start_pos)
		core_beam.add_point(end_pos)

	if outer_beam:
		outer_beam.clear_points()
		outer_beam.add_point(start_pos)
		outer_beam.add_point(end_pos)

	if glow_beam:
		glow_beam.clear_points()
		glow_beam.add_point(start_pos)
		glow_beam.add_point(end_pos)

func set_target(new_target: Node2D) -> void:
	target = new_target

func set_owner_position(pos: Vector2) -> void:
	owner_pos = pos
	params["owner_pos"] = pos
