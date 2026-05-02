extends Node

signal mobile_move(output: Vector2)

var joystick: Control = null
var joystick_output := Vector2.ZERO
var joystick_pressed := false
var _last_output := Vector2.ZERO


func register_joystick(node: Control) -> void:
	joystick = node


func _process(_delta: float) -> void:
	if joystick == null:
		return
	var out := Vector2.ZERO
	if joystick.has_method("get_vector"):
		out = joystick.get_vector()
	elif joystick.has("output"):
		out = joystick.get("output")
	if out != _last_output:
		_last_output = out
		joystick_output = out
		joystick_pressed = out.length() > 0.05
		mobile_move.emit(out)
