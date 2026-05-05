class_name WeaponEffectManager
extends Node

var effect_pool: Dictionary = {}
var effect_scenes: Dictionary = {}
var active_effects: Array = []
var _warned_missing_effects: Array = []

var _effect_script_map: Dictionary = {
	"laser_charge": "res://scripts/effects/laser_charge.gd",
	"laser_beam_vfx": "res://scripts/effects/laser_beam_vfx.gd",
	"railgun_charge": "res://scripts/effects/railgun_charge.gd",
	"railgun_projectile": "res://scripts/effects/railgun_projectile_vfx.gd",
	"cannon_muzzle": "res://scripts/effects/cannon_muzzle.gd",
	"cannon_smoke": "res://scripts/effects/cannon_smoke.gd",
	"missile_launch": "res://scripts/effects/missile_launch.gd",
	"missile_trail": "res://scripts/effects/missile_trail.gd",
	"missile_explosion": "res://scripts/effects/missile_explosion.gd",
}

func _ready() -> void:
	_preload_effect_scenes()

func _preload_effect_scenes() -> void:
	for effect_name in _effect_script_map.keys():
		var scene_path = _get_scene_path(effect_name)
		if ResourceLoader.exists(scene_path):
			var loaded = load(scene_path)
			if loaded is PackedScene:
				effect_scenes[effect_name] = loaded
			else:
				push_warning("[WeaponEffectManager] Scene at '" + scene_path + "' is not a valid PackedScene (type: " + str(typeof(loaded)) + ")")
		else:
			push_warning("[WeaponEffectManager] Effect scene file not found: " + scene_path)

func _get_scene_path(effect_name: String) -> String:
	return "res://scenes/effects/" + _effect_script_map[effect_name].get_file().replace(".gd", ".tscn")

func spawn_effect(effect_name: String, position: Vector2, direction: Vector2 = Vector2.RIGHT, params: Dictionary = {}) -> Node2D:
	var scene = effect_scenes.get(effect_name)
	if not scene:
		if not effect_name in _warned_missing_effects:
			push_warning("[WeaponEffectManager] Effect scene not found: " + effect_name + " (path would be: " + _get_scene_path(effect_name) + ")")
			_warned_missing_effects.append(effect_name)
		return null

	var effect = scene.instantiate()
	effect.global_position = position
	effect.global_rotation = direction.angle()

	var params_copy = params.duplicate(true)
	params_copy["direction"] = direction
	effect.setup(params_copy)

	add_child(effect)
	active_effects.append(effect)

	effect.tree_exited.connect(_on_effect_finished.bind(effect))
	return effect

func spawn_effect_with_rotation(effect_name: String, position: Vector2, rotation: float, params: Dictionary = {}) -> Node2D:
	var scene = effect_scenes.get(effect_name)
	if not scene:
		return null

	var effect = scene.instantiate()
	effect.global_position = position
	effect.global_rotation = rotation

	var params_copy = params.duplicate(true)
	effect.setup(params_copy)

	add_child(effect)
	active_effects.append(effect)

	effect.tree_exited.connect(_on_effect_finished.bind(effect))
	return effect

func _on_effect_finished(effect: Node) -> void:
	var idx = active_effects.find(effect)
	if idx >= 0:
		active_effects.remove_at(idx)

func clear_all_effects() -> void:
	for effect in active_effects:
		if is_instance_valid(effect):
			effect.queue_free()
	active_effects.clear()

func call_effect_method(effect_name: String, method_name: String) -> void:
	for effect in active_effects:
		if effect.name.begins_with(effect_name):
			if effect.has_method(method_name):
				effect.call(method_name)
