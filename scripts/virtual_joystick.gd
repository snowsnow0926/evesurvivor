class_name VirtualJoystick
extends Control

## Virtual joystick with touch support.
## Outputs a normalized direction vector via `output` and `is_pressed`.

signal moved(output: Vector2)

@export var deadzone: float = 0.15
@export var joystick_radius: float = 80.0
@export var knob_radius: float = 30.0
@export var auto_hide_on_mouse: bool = true

var output := Vector2.ZERO
var is_pressed := false
var _touch_index: int = -1
var _knob_offset := Vector2.ZERO
var _base_pos := Vector2.ZERO

@onready var _base: PanelContainer = $Base
@onready var _knob: ColorRect = $Knob


func _ready() -> void:
	# 不再默认隐藏 — 摇杆在触屏设备上也始终可见，让玩家能找到
	knob_radius = _knob.size.x * 0.5
	_knob.pivot_offset = _knob.size * 0.5
	_base.pivot_offset = _base.size * 0.5


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _touch_index < 0:
			var touch_pos := event.position
			var local := _global_to_local(touch_pos)
			if _is_in_joystick_zone(local):
				_touch_index = event.index
				_base_pos = local
				is_pressed = true
				visible = true
				_update_knob(local)
				_update_output(local)
				_set_base_position(touch_pos)
	else:
		if event.index == _touch_index:
			_reset()
	return


func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != _touch_index:
		return
	var touch_pos := event.position
	var local := _global_to_local(touch_pos)
	_update_knob(local)
	_update_output(local)
	return


func _is_in_joystick_zone(local_pos: Vector2) -> bool:
	return local_pos.distance_to(Vector2.ZERO) < joystick_radius * 1.8


func _global_to_local(global: Vector2) -> Vector2:
	return global - global_position


func _update_knob(local: Vector2) -> void:
	var delta := local - _base_pos
	var dist := delta.length()
	var max_dist: float = joystick_radius
	var clamped_vec: Vector2 = delta.normalized() * minf(dist, max_dist)
	_knob_offset = clamped_vec
	_knob.position = _base.size * 0.5 + clamped_vec - _knob.size * 0.5


func _update_output(local: Vector2) -> void:
	var delta := local - _base_pos
	var dist := delta.length()
	if dist < deadzone * joystick_radius:
		output = Vector2.ZERO
	else:
		var strength: float = (dist - deadzone * joystick_radius) / (joystick_radius * (1.0 - deadzone))
		output = delta.normalized() * strength
	moved.emit(output)


func _set_base_position(screen_pos: Vector2) -> void:
	var viewport := get_viewport_rect()
	var clamped_pos := Vector2(
		clampf(screen_pos.x, joystick_radius, viewport.size.x - joystick_radius),
		clampf(screen_pos.y, joystick_radius, viewport.size.y - joystick_radius)
	)
	position = clamped_pos - _base.size * 0.5
	_base_pos = _base.size * 0.5


func _reset() -> void:
	_touch_index = -1
	is_pressed = false
	output = Vector2.ZERO
	_knob_offset = Vector2.ZERO
	_knob.position = _base.size * 0.5 - _knob.size * 0.5
	moved.emit(Vector2.ZERO)
	# 摇杆始终可见，不需要再隐藏


func get_vector() -> Vector2:
	return output
