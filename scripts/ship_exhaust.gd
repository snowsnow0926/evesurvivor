class_name ShipExhaust
extends Node2D

const _OFFSET_DIST: float = 28.0

@onready var _particles: GPUParticles2D = $ExhaustParticles
@onready var _mat: ParticleProcessMaterial = _particles.process_material as ParticleProcessMaterial

func update_exhaust(ship_angle: float, ship_speed: float, ship_global_pos: Vector2) -> void:
	var rear_local := Vector2.from_angle(ship_angle + PI) * _OFFSET_DIST
	global_position = ship_global_pos + rear_local
	rotation = ship_angle + PI

	var sr := clampf(ship_speed / 300.0, 0.0, 1.0)
	var base_max := 35
	if PerformanceSettings and PerformanceSettings.is_mobile:
		base_max = 20
	_particles.amount = int(lerpf(8.0, float(base_max), sr))
	_mat.initial_velocity_min = lerpf(50.0, 90.0, sr)
	_mat.initial_velocity_max = lerpf(100.0, 180.0, sr)
	_mat.scale_min = lerpf(1.5, 3.5, sr)
	_mat.scale_max = lerpf(3.0, 7.0, sr)
