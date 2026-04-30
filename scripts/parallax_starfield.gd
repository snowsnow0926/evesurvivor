extends Node2D

@export var star_layer_count: int = 3

var camera: Camera2D
var layers: Array = []

class StarLayer:
	var stars: Array = []
	var parallax: float
	var color: Color

	func _init(p_parallax: float, p_color: Color) -> void:
		parallax = p_parallax
		color = p_color

func _ready() -> void:
	camera = get_viewport().get_camera_2d()
	if camera:
		position = camera.global_position
	_add_layers()
	process_physics_priority = -100

func _physics_process(_delta: float) -> void:
	if not camera or not is_instance_valid(camera):
		return
	position = camera.global_position
	queue_redraw()

func _add_layers() -> void:
	var colors = [
		Color(0.7, 0.8, 1.0, 0.55),
		Color(0.85, 0.9, 1.0, 0.45),
		Color(1.0, 0.95, 0.85, 0.35),
	]
	var parallaxes = [0.15, 0.35, 0.6]
	var densities = [130.0, 90.0, 55.0]

	for i in range(star_layer_count):
		var layer = StarLayer.new(parallaxes[i], colors[i])
		_generate_stars(layer, densities[i])
		layers.append(layer)

func _generate_stars(layer: StarLayer, density: float) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = randi()
	var spread = 5000.0
	var count = int(density * 8)
	for _i in range(count):
		var pos = Vector2(
			rng.randf_range(-spread, spread),
			rng.randf_range(-spread, spread)
		)
		var size = rng.randf_range(0.8, 2.2)
		var twinkle_offset = rng.randf_range(0, TAU)
		var twinkle_speed = rng.randf_range(1.5, 4.0)
		layer.stars.append({"pos": pos, "size": size, "twinkle_offset": twinkle_offset, "twinkle_speed": twinkle_speed})

func _draw() -> void:
	var vp_rect = get_viewport_rect()
	var center = vp_rect.size * 0.5
	var radius = maxf(vp_rect.size.x, vp_rect.size.y) * 0.8
	var now = Time.get_ticks_msec() / 1000.0

	for layer in layers:
		for star in layer.stars:
			var world_star = star["pos"]
			var screen_pos = center + (world_star - global_position) * (1.0 - layer.parallax)
			var dist = screen_pos.distance_to(center)
			if dist > radius:
				continue
			var twinkle = 0.65 + 0.35 * sin(now * star["twinkle_speed"] + star["twinkle_offset"])
			var alpha = layer.color.a * twinkle * (1.0 - dist / radius * 0.6)
			var c = layer.color
			c.a = alpha
			draw_circle(screen_pos, star["size"], c)
