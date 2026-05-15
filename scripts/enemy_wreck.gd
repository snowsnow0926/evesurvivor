class_name EnemyWreck
extends Node2D

const WreckShader := preload("res://shaders/wreck_effect.gdshader")

var wreck_sprite: Sprite2D
@onready var explosion_particles: CPUParticles2D = $ExplosionParticles
@onready var smoke_particles: CPUParticles2D = $SmokeParticles

var _rotation_speed: float = 0.0
var _smoke_duration: float = 2.0
var _fade_duration: float = 2.0
var _is_fading: bool = false
var _total_lifetime: float = 0.0

func _ready() -> void:
	_rotation_speed = randf_range(-0.3, 0.3)
	_setup_wreck_sprite()
	_configure_particles()

func _setup_wreck_sprite() -> void:
	wreck_sprite = Sprite2D.new()
	wreck_sprite.name = "WreckSprite"
	add_child(wreck_sprite)

	var mat := ShaderMaterial.new()
	mat.shader = WreckShader
	mat.set_shader_parameter("burn_intensity", 0.5)
	mat.set_shader_parameter("gray_mult", 0.35)
	mat.set_shader_parameter("alpha_drain", 0.9)
	wreck_sprite.material = mat

func _configure_particles() -> void:
	var is_mobile = PerformanceSettings.is_mobile if PerformanceSettings else false
	explosion_particles.amount = 10 if is_mobile else 20
	explosion_particles.color = Color(1.0, 0.4, 0.0, 1.0)
	explosion_particles.finished.connect(_on_explosion_finished)

	smoke_particles.amount = 15 if is_mobile else 30
	smoke_particles.color = Color(0.4, 0.4, 0.4, 0.6)
	if PerformanceSettings and not PerformanceSettings.wreck_smoke_enabled:
		smoke_particles.emitting = false

func _on_explosion_finished() -> void:
	if is_instance_valid(explosion_particles):
		explosion_particles.queue_free()

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
	smoke_particles.emitting = true
	if PerformanceSettings and not PerformanceSettings.wreck_smoke_enabled:
		smoke_particles.emitting = false

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
