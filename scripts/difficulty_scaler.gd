class_name DifficultyScaler
extends Node

## Manages combo system.

var combo_count: int = 0
var combo_timer: float = 0.0
var combo_timeout: float = 3.0
var combo_multiplier: float = 1.0

var _difficulty_tick_counter: int = 0

func setup_stage(stage_strength: float, stage_density: float, player_level: int) -> void:
	combo_count = 0
	combo_timer = 0.0
	combo_multiplier = 1.0

func update_combo(delta: float) -> void:
	_difficulty_tick_counter += 1
	if combo_count > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0
			combo_multiplier = _get_combo_multiplier()

func on_enemy_killed() -> void:
	combo_count += 1
	combo_timer = combo_timeout
	combo_multiplier = _get_combo_multiplier()

func _get_combo_multiplier() -> float:
	if combo_count >= 30:
		return 3.0
	elif combo_count >= 20:
		return 2.5
	elif combo_count >= 10:
		return 2.0
	elif combo_count >= 5:
		return 1.5
	return 1.0

func reset() -> void:
	combo_count = 0
	combo_timer = 0.0
	combo_multiplier = 1.0
