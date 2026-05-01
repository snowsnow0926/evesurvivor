extends Node

var data: Dictionary = {}

func _ready() -> void:
	_load_balance()

func _load_balance() -> void:
	var path = "res://resources/game_balance.json"
	if not ResourceLoader.exists(path):
		push_warning("[GameBalance] balance file not found: " + path)
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[GameBalance] failed to open: " + path)
		return
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	var err = json.parse(content)
	if err != OK:
		push_warning("[GameBalance] JSON parse error: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return
	data = json.data
	print("[GameBalance] Loaded ", data.size(), " top-level sections")

func get_value(section: String, key: String, default = null):
	if not data.has(section):
		return default
	if not data[section].has(key):
		return default
	return data[section][key]

func get_player(key: String, default = null):
	return get_value("player", key, default)

func get_weapon(key: String, subkey: String, default = null):
	if not data.has("weapons"):
		return default
	if not data["weapons"].has(key):
		return default
	if not data["weapons"][key].has(subkey):
		return default
	return data["weapons"][key][subkey]

func get_enemy(key: String, subkey: String, default = null):
	if not data.has("enemies"):
		return default
	if not data["enemies"].has(key):
		return default
	if not data["enemies"][key].has(subkey):
		return default
	return data["enemies"][key][subkey]

func get_reward(enemy_type: String):
	return get_value("rewards", enemy_type, {"coin": 10, "mineral": 2})

func get_upgrade(upgrade_id: String):
	return get_value("upgrades", upgrade_id, {})

func get_spawn(key: String, default = null):
	return get_value("spawn", key, default)

func get_difficulty(key: String, default = null):
	return get_value("difficulty", key, default)

func get_settlement(key: String, default = null):
	return get_value("settlement", key, default)
