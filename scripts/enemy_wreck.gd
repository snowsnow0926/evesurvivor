class_name EnemyWreck
extends Node2D

const WreckShader := preload("res://shaders/wreck_effect.gdshader")

var wreck_sprite: Sprite2D
var explosion_particles: CPUParticles2D
var smoke_particles: CPUParticles2D
var _rotation_speed: float = 0.0
var _smoke_timer: float = 0.0
var _smoke_interval: float = 0.4
var _total_lifetime: float = 0.0
var _smoke_duration: float = 2.0
var _fade_duration: float = 2.0
var _is_fading: bool = false

func _ready() -> void:
	_rotation_speed = randf_range(-0.3, 0.3)
	_spawn_nodes()

func _spawn_nodes() -> void:
	wreck_sprite = Sprite2D.new()
	wreck_sprite.name = "WreckSprite"
	add_child(wreck_sprite)

	var mat := ShaderMaterial.new()
	mat.shader = WreckShader
	mat.set_shader_parameter("burn_intensity", 0.5)
	mat.set_shader_parameter("gray_mult", 0.35)
	mat.set_shader_parameter("alpha_drain", 0.9)
	wreck_sprite.material = mat

	explosion_particles = CPUParticles2D.new()
	explosion_particles.name = "ExplosionParticles"
	explosion_particles.z_index = 1
	add_child(explosion_particles)
	_configure_explosion_particles()

	smoke_particles = CPUParticles2D.new()
	smoke_particles.name = "SmokeParticles"
	smoke_particles.z_index = 0
	smoke_particles.emitting = false
	add_child(smoke_particles)
	_configure_smoke_particles()

func _configure_explosion_particles() -> void:
	explosion_particles.amount = 20
	explosion_particles.lifetime = 0.5
	explosion_particles.one_shot = true
	explosion_particles.emission_shape = 0
	explosion_particles.direction = Vector2(0, -1)
	explosion_particles.spread = 180.0
	explosion_particles.initial_velocity_min = 80.0
	explosion_particles.initial_velocity_max = 200.0
	explosion_particles.scale_amount_min = 2.0
	explosion_particles.scale_amount_max = 6.0
	explosion_particles.gravity = Vector2(0, 50)
	explosion_particles.color = Color(1.0, 0.4, 0.0, 1.0)
	explosion_particles.queue_redraw()

func _configure_smoke_particles() -> void:
	smoke_particles.amount = 30
	smoke_particles.lifetime = 1.5
	smoke_particles.one_shot = false
	smoke_particles.emission_shape = 0
	smoke_particles.direction = Vector2(0, -1)
	smoke_particles.spread = 60.0
	smoke_particles.initial_velocity_min = 15.0
	smoke_particles.initial_velocity_max = 40.0
	smoke_particles.scale_amount_min = 6.0
	smoke_particles.scale_amount_max = 16.0
	smoke_particles.gravity = Vector2(0, -10)
	smoke_particles.color = Color(0.4, 0.4, 0.4, 0.6)
	smoke_particles.queue_redraw()

func setup(
	tex: Texture2D,
	scale_val: float,
	rotation: float,
	particle_color: Color,
	particle_count: int,
	duration: float = 3.0
) -> void:
	_total_lifetime = duration
	_smoke_duration = duration * 0.6
	_fade_duration = duration * 0.5
	if wreck_sprite != null:
		wreck_sprite.texture = tex
		wreck_sprite.scale = Vector2.ONE * scale_val
		wreck_sprite.rotation = rotation
	rotation_degrees = rotation
	if explosion_particles != null:
		explosion_particles.color = particle_color
		explosion_particles.amount = particle_count
		explosion_particles.emitting = true
		explosion_particles.finished.connect(_on_explosion_finished)
	smoke_particles.emitting = true

func _on_explosion_finished() -> void:
	if is_instance_valid(explosion_particles):
		explosion_particles.queue_free()

func _process(delta: float) -> void:
	rotation_degrees += _rotation_speed
	_total_lifetime -= delta

	if _total_lifetime <= _fade_duration and not _is_fading:
		_start_fade()

	if _is_fading:
		var fade_t: float = 1.0 - (_total_lifetime / _fade_duration)
		if fade_t > 0.0:
			modulate.a = 1.0 - fade_t

	if _total_lifetime <= 0.0:
		queue_free()

func _start_fade() -> void:
	_is_fading = true
	if is_instance_valid(smoke_particles):
		smoke_particles.emitting = false
		smoke_particles.queue_free()
