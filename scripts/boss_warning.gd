extends Control

var _flash_tween: Tween

func _ready() -> void:
	visible = false

func show_warning() -> void:
	if visible:
		return
	visible = true
	_start_flash()

func hide_warning() -> void:
	visible = false
	_stop_flash()

func _start_flash() -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.set_loops()
	_flash_tween.tween_property($Panel/Label, "modulate", Color(1.0, 0.2, 0.2, 1.0), 0.4)
	_flash_tween.tween_property($Panel/Label, "modulate", Color(1.0, 0.6, 0.6, 1.0), 0.4)

func _stop_flash() -> void:
	if _flash_tween:
		_flash_tween.kill()
		_flash_tween = null
