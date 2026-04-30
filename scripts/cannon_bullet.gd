class_name CannonBullet
extends Area2D

var direction: Vector2
var damage: float = 25.0
var speed: float = 800.0
var max_range: float = 400.0
var crit_rate: float = 0.05
var crit_mult: float = 1.2
var traveled_distance: float = 0.0
var has_hit_first: bool = false
var reference: Node

var pierce_count: int = 1
var damage_decay: float = 0.2
var hit_count: int = 0
var explode_chance: float = 0.0
var explode_radius: float = 80.0

var polygon: Node2D
var trail_points: Array = []
var trail_max_length: int = 10

func _ready() -> void:
	polygon = $Polygon2D
	body_entered.connect(_on_body_entered)
	print("[CannonBullet] _ready called")

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
	var width = 5.0
	for i in range(trail_points.size() - 1):
		var alpha = 1.0 - float(i) / float(trail_points.size())
		var color = Color(1.0, 0.55, 0.1, alpha * 0.6)
		var start = trail_points[i] - global_position
		var end = trail_points[i + 1] - global_position
		draw_line(start, end, color, width * alpha, true)

func setup(dir: Vector2, dmg: float, spd: float, rng: float, crit_r: float, crit_m: float, ref: Node, pierce: int = 1, decay: float = 0.2, explode_ch: float = 0.0, explode_rad: float = 80.0) -> void:
	direction = dir.normalized()
	damage = dmg
	speed = spd
	max_range = rng
	crit_rate = crit_r
	crit_mult = crit_m
	reference = ref
	traveled_distance = 0.0
	has_hit_first = false
	pierce_count = pierce
	damage_decay = decay
	hit_count = 0
	explode_chance = explode_ch
	explode_radius = explode_rad

func _on_body_entered(body: Node) -> void:
	if not body.has_method("take_damage"):
		return
	if hit_count >= pierce_count:
		return

	hit_count += 1
	var is_crit = randf() < crit_rate
	var final_damage = damage * pow(1.0 - damage_decay, hit_count - 1) * (crit_mult if is_crit else 1.0)
	body.take_damage(final_damage)

	if reference and reference.has_method("on_bullet_hit"):
		reference.on_bullet_hit(self, body, is_crit)

	_try_explode(global_position)

	if hit_count >= pierce_count:
		queue_free()

func _try_explode(pos: Vector2) -> void:
	if explode_chance <= 0.0:
		return
	if randf() < explode_chance:
		if reference and reference.has_method("create_explosion"):
			reference.create_explosion(pos, explode_radius, damage * 0.5)
