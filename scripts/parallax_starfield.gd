extends Node2D

@export var star_layer_count: int = 3

var camera: Camera2D
var layers: Array = []

class StarLayer:
	var stars: Array = []
	var parallax: float
	var color: Color
	var size_range: Vector2

	func _init(p_parallax: float, p_color: Color, p_size_range: Vector2 = Vector2(0.8, 2.2)) -> void:
		parallax = p_parallax
		color = p_color
		size_range = p_size_range

var _camera_prev: Vector2 = Vector2.ZERO
var _time: float = 0.0

func _ready() -> void:
	camera = get_viewport().get_camera_2d()
	if camera:
		_camera_prev = camera.global_position
		position = camera.global_position
	_add_layers()
	process_physics_priority = -100

func _physics_process(delta: float) -> void:
	if not camera or not is_instance_valid(camera):
		return

	var cam_pos := camera.global_position
	_camera_prev = cam_pos
	position = cam_pos
	_time += delta
	queue_redraw()

func _add_layers() -> void:
	var mobile_mult: float = 1.0
	if PerformanceSettings.is_mobile:
		mobile_mult = PerformanceSettings.starfield_density_mult

	var configs: Array[Dictionary] = [
		{parallax = 0.12, color = Color(0.78, 0.86, 1.0, 0.60), density = 150.0, size_range = Vector2(0.6, 1.5)},
		{parallax = 0.30, color = Color(0.90, 0.95, 1.0, 0.55), density = 100.0, size_range = Vector2(1.0, 2.2)},
		{parallax = 0.55, color = Color(1.0, 0.98, 0.90, 0.50), density = 60.0, size_range = Vector2(1.5, 3.0)},
	]

	for i in range(mini(star_layer_count, configs.size())):
		var cfg: Dictionary = configs[i]
		var layer := StarLayer.new(cfg.parallax, cfg.color, cfg.size_range)
		_generate_stars(layer, cfg.density * mobile_mult)
		layers.append(layer)

func _generate_stars(layer: StarLayer, density: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = randi()
	var spread := 5000.0
	var count := int(density * 8)
	for _i in range(count):
		var star_pos := Vector2(
			rng.randf_range(-spread, spread),
			rng.randf_range(-spread, spread)
		)
		var size := rng.randf_range(layer.size_range.x, layer.size_range.y)
		var twinkle_offset := rng.randf_range(0.0, TAU)
		var twinkle_speed := rng.randf_range(1.5, 4.0)
		var color_idx := rng.randf()
		layer.stars.append({
			pos = star_pos,
			size = size,
			twinkle_offset = twinkle_offset,
			twinkle_speed = twinkle_speed,
			color_idx = color_idx,
		})

func _draw() -> void:
	var vp_rect := get_viewport_rect()
	var center := vp_rect.size * 0.5
	var radius := maxf(vp_rect.size.x, vp_rect.size.y) * 0.82

	for layer in layers:
		for star in layer.stars:
			var world_star: Vector2 = star["pos"]
			var screen_pos: Vector2 = center + (world_star - global_position) * (1.0 - layer.parallax)
			var dist: float = screen_pos.distance_to(center)
			if dist > radius:
				continue

			var twinkle: float = 0.65 + 0.35 * sin(_time * star["twinkle_speed"] + star["twinkle_offset"])
			var edge_fade: float = 1.0 - dist / radius * 0.55
			var alpha: float = layer.color.a * twinkle * edge_fade

			var base: Color = layer.color
			base.a = alpha
			var color_idx: float = star["color_idx"]
			if color_idx < 0.33:
				base = Color(0.6, 0.7, 1.0, alpha)
			elif color_idx < 0.66:
				base = Color(0.8, 0.85, 1.0, alpha)
			else:
				base = Color(1.0, 0.95, 0.85, alpha)

			var star_size: float = star["size"]
			draw_circle(screen_pos, star_size * 0.5, Color(base.r, base.g, base.b, minf(alpha * 1.4, 1.0)))
			draw_circle(screen_pos, star_size * 1.5, Color(base.r, base.g, base.b, alpha * 0.4))
			draw_circle(screen_pos, star_size * 2.5, Color(base.r * 0.5, base.g * 0.6, base.b * 0.8, alpha * 0.15))
