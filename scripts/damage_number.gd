extends Node2D

const FLOAT_DISTANCE: float = 50.0
const FLOAT_DURATION: float = 0.8
const BASE_FONT_SIZE: int = 20

var lifetime: float = 0.0
var duration: float = FLOAT_DURATION
var start_pos: Vector2 = Vector2.ZERO
var damage_amount: float = 0.0
var is_crit: bool = false
var is_enemy_damage: bool = false

func _ready() -> void:
	pass

func setup(world_pos: Vector2, amount: float, is_crit_hit: bool = false, enemy_dmg: bool = false) -> void:
	global_position = world_pos
	damage_amount = amount
	is_crit = is_crit_hit
	is_enemy_damage = enemy_dmg
	start_pos = global_position
	duration = FLOAT_DURATION
	lifetime = 0.0

	var label = $DamageLabel
	if not label:
		push_error("[DamageNumber] DamageLabel child not found!")
		return

	if is_enemy_damage:
		label.text = "-%.0f" % damage_amount
		label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		if is_crit:
			label.add_theme_font_size_override("font_size", BASE_FONT_SIZE + 8)
		else:
			label.add_theme_font_size_override("font_size", BASE_FONT_SIZE)
	else:
		label.text = "%.0f" % damage_amount
		if is_crit:
			label.text += "!"
			label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
			label.add_theme_font_size_override("font_size", BASE_FONT_SIZE + 10)
		else:
			label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
			label.add_theme_font_size_override("font_size", BASE_FONT_SIZE)

func _process(delta: float) -> void:
	lifetime += delta
	var t = lifetime / duration

	if t >= 1.0:
		queue_free()
		return

	var label = $DamageLabel
	if label:
		var x_offset = randf_range(-10.0, 10.0)
		global_position.x = start_pos.x + x_offset
		global_position.y = start_pos.y - FLOAT_DISTANCE * t

		var mod = Color(1.0, 1.0, 1.0, 1.0 - t)
		label.modulate = mod
