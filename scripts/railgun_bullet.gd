extends Area2D

var direction: Vector2 = Vector2.ZERO
var damage: float = 30.0
var speed: float = 1000.0
var crit_rate: float = 0.35
var crit_mult: float = 1.5
var game_manager: Node2D
var traveled_distance: float = 0.0
var max_range: float = 400.0

var polygon: Node2D
var trail_points: Array = []
var trail_max_length: int = 6

func _ready() -> void:
	polygon = $Polygon2D
	body_entered.connect(_on_body_entered)
	print("[RailgunBullet] _ready called")

func _physics_process(delta: float) -> void:
	var step_vec = direction * speed * delta
	global_position += step_vec
	traveled_distance += step_vec.length()

	if traveled_distance >= max_range:
		queue_free()
		return

	if polygon:
		polygon.rotation = direction.angle() + PI / 2

	trail_points.push_front(global_position)
	if trail_points.size() > trail_max_length:
		trail_points.pop_back()

	queue_redraw()

func _draw() -> void:
	if trail_points.size() < 2:
		return
	var width = 4.0
	for i in range(trail_points.size() - 1):
		var alpha = 1.0 - float(i) / float(trail_points.size())
		var color = Color(0.2, 1.0, 0.8, alpha * 0.6)
		var start = trail_points[i] - global_position
		var end = trail_points[i + 1] - global_position
		draw_line(start, end, color, width * alpha, true)

func setup(dir: Vector2, dmg: float, spd: float, rng: float, cr: float, cm: float, gm: Node2D) -> void:
	direction = dir.normalized()
	damage = dmg
	speed = spd
	crit_rate = cr
	crit_mult = cm
	game_manager = gm
	max_range = rng
	traveled_distance = 0.0

func _on_body_entered(body: Node) -> void:
	if not body.has_method("take_damage"):
		return
	var is_crit = randf() < crit_rate
	var final_damage = damage * (crit_mult if is_crit else 1.0)
	body.take_damage(final_damage, is_crit)
	queue_free()
