extends Node

var selected_race_id: int = 0
var player_name: String = ""
var selected_ship_id: int = 1  # 默认护卫舰，避免与0值混淆
var unlocked_ships: Array = []
var equipment_inventory: Array = []
var equipped_weapons: Dictionary = {}
var equipped_armor: Dictionary = {}
var star_coin: int = 0
var minerals_low: int = 0
var minerals_mid: int = 0
var minerals_high: int = 0
var upgraded_ships: Dictionary = {}
var research_progress: Dictionary = {}
var ship_damaged: bool = false
var total_kills: int = 0
var total_deaths: int = 0
var highest_level: int = 1
var first_run: bool = true
var last_run_reason: String = ""
var pre_run_coin: int = 0
var pre_run_minerals_total: int = 0
var pre_run_minerals_low: int = 0
var pre_run_minerals_mid: int = 0
var pre_run_minerals_high: int = 0
var selected_chapter_id: int = 1
var selected_stage_id: int = 1
var unlocked_stages: Array = [1]  # stage 1 unlocked by default
var stage_first_complete: Array = []  # stages that have been first-cleared (timer survived + boss killed)
var stage6_timer_used: bool = false  # stage 6 timer consumed, future runs are infinite

const SAVE_PATH := "user://game_save.cfg"
const SAVE_SLOTS := 3
const DEBUG := false

var current_save_slot: int = -1

func _debug(msg: String) -> void:
	if DEBUG:
		print("[GameState] ", msg)

func _ready() -> void:
	load_game()

func save_game() -> bool:
	var cfg = ConfigFile.new()
	cfg.set_value("meta", "version", 1)
	cfg.set_value("meta", "saved_at", Time.get_datetime_string_from_system())

	cfg.set_value("progress", "star_coin", star_coin)
	cfg.set_value("progress", "minerals_low", minerals_low)
	cfg.set_value("progress", "minerals_mid", minerals_mid)
	cfg.set_value("progress", "minerals_high", minerals_high)
	cfg.set_value("progress", "total_kills", total_kills)
	cfg.set_value("progress", "total_deaths", total_deaths)
	cfg.set_value("progress", "highest_level", highest_level)

	cfg.set_value("progress", "ship_damaged", ship_damaged)
	cfg.set_value("progress", "first_run", first_run)
	cfg.set_value("progress", "unlocked_stages", unlocked_stages)
	cfg.set_value("progress", "stage_first_complete", stage_first_complete)
	cfg.set_value("progress", "stage6_timer_used", stage6_timer_used)

	cfg.set_value("player", "selected_race_id", selected_race_id)
	cfg.set_value("player", "selected_ship_id", selected_ship_id)
	cfg.set_value("player", "player_name", player_name)

	cfg.set_value("ships", "unlocked_ships", unlocked_ships)
	cfg.set_value("ships", "upgraded_ships", upgraded_ships)

	cfg.set_value("research", "research_progress", research_progress)

	cfg.set_value("equipment", "equipment_inventory", equipment_inventory)
	cfg.set_value("equipment", "equipped_weapons", equipped_weapons)
	cfg.set_value("equipment", "equipped_armor", equipped_armor)

	var path = get_save_slot_path(current_save_slot)
	var err = cfg.save(path)
	if err != OK:
		push_error("[GameState] Failed to save game: error " + str(err))
		return false
	print("[GameState] Game saved to ", path)
	return true

func load_game() -> bool:
	var path = get_save_slot_path(current_save_slot)
	if not FileAccess.file_exists(path):
		if current_save_slot >= 0:
			print("[GameState] No save file for slot %d, trying legacy path" % current_save_slot)
		if FileAccess.file_exists(SAVE_PATH):
			path = SAVE_PATH
		else:
			print("[GameState] No save file found, starting fresh")
			return false

	var cfg = ConfigFile.new()
	var err = cfg.load(path)
	if err != OK:
		push_error("[GameState] Failed to load game: error " + str(err))
		return false

	star_coin = cfg.get_value("progress", "star_coin", 0)
	minerals_low = cfg.get_value("progress", "minerals_low", 0)
	minerals_mid = cfg.get_value("progress", "minerals_mid", 0)
	minerals_high = cfg.get_value("progress", "minerals_high", 0)
	total_kills = cfg.get_value("progress", "total_kills", 0)
	total_deaths = cfg.get_value("progress", "total_deaths", 0)
	highest_level = cfg.get_value("progress", "highest_level", 1)
	ship_damaged = cfg.get_value("progress", "ship_damaged", false)
	first_run = cfg.get_value("progress", "first_run", true)
	unlocked_stages = cfg.get_value("progress", "unlocked_stages", [1])
	stage_first_complete = cfg.get_value("progress", "stage_first_complete", [])
	stage6_timer_used = cfg.get_value("progress", "stage6_timer_used", false)

	selected_race_id = cfg.get_value("player", "selected_race_id", 0)
	selected_ship_id = cfg.get_value("player", "selected_ship_id", 1)
	player_name = cfg.get_value("player", "player_name", "")

	unlocked_ships = cfg.get_value("ships", "unlocked_ships", [])
	upgraded_ships = cfg.get_value("ships", "upgraded_ships", {})

	equipment_inventory = cfg.get_value("equipment", "equipment_inventory", [])
	equipped_weapons = cfg.get_value("equipment", "equipped_weapons", {})
	equipped_armor = cfg.get_value("equipment", "equipped_armor", {})

	if not equipment_inventory is Array:
		push_warning("[GameState] equipment_inventory corrupted, resetting")
		equipment_inventory = []

	print("[GameState] Game loaded from ", SAVE_PATH)
	_migrate_equipped_armor_to_array()
	return true

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("[GameState] Save file deleted")

func get_save_slot_path(slot_idx: int) -> String:
	return "user://save_slot_%d.cfg" % slot_idx

func save_save_slot(slot_idx: int) -> bool:
	if slot_idx < 0:
		print("[GameState] No save slot selected, skipping save")
		return false
	var cfg = ConfigFile.new()
	cfg.set_value("meta", "version", 1)
	cfg.set_value("meta", "saved_at", Time.get_datetime_string_from_system())

	cfg.set_value("progress", "star_coin", star_coin)
	cfg.set_value("progress", "minerals_low", minerals_low)
	cfg.set_value("progress", "minerals_mid", minerals_mid)
	cfg.set_value("progress", "minerals_high", minerals_high)
	cfg.set_value("progress", "total_kills", total_kills)
	cfg.set_value("progress", "total_deaths", total_deaths)
	cfg.set_value("progress", "highest_level", highest_level)

	cfg.set_value("progress", "ship_damaged", ship_damaged)
	cfg.set_value("progress", "first_run", first_run)
	cfg.set_value("progress", "unlocked_stages", unlocked_stages)
	cfg.set_value("progress", "stage_first_complete", stage_first_complete)
	cfg.set_value("progress", "stage6_timer_used", stage6_timer_used)

	cfg.set_value("player", "selected_race_id", selected_race_id)
	cfg.set_value("player", "selected_ship_id", selected_ship_id)
	cfg.set_value("player", "player_name", player_name)

	cfg.set_value("ships", "unlocked_ships", unlocked_ships)
	cfg.set_value("ships", "upgraded_ships", upgraded_ships)

	cfg.set_value("research", "research_progress", research_progress)

	cfg.set_value("equipment", "equipment_inventory", equipment_inventory)
	cfg.set_value("equipment", "equipped_weapons", equipped_weapons)
	cfg.set_value("equipment", "equipped_armor", equipped_armor)

	var path = get_save_slot_path(slot_idx)
	var err = cfg.save(path)
	if err != OK:
		push_error("[GameState] Failed to save slot %d: error %d" % [slot_idx, err])
		return false
	print("[GameState] Saved to slot %d: %s" % [slot_idx, path])
	return true

func load_save_slot(slot_idx: int) -> bool:
	var path = get_save_slot_path(slot_idx)
	if not FileAccess.file_exists(path):
		print("[GameState] No save file for slot %d" % slot_idx)
		return false

	var cfg = ConfigFile.new()
	var err = cfg.load(path)
	if err != OK:
		push_error("[GameState] Failed to load slot %d: error %d" % [slot_idx, err])
		return false

	star_coin = cfg.get_value("progress", "star_coin", 0)
	minerals_low = cfg.get_value("progress", "minerals_low", 0)
	minerals_mid = cfg.get_value("progress", "minerals_mid", 0)
	minerals_high = cfg.get_value("progress", "minerals_high", 0)
	total_kills = cfg.get_value("progress", "total_kills", 0)
	total_deaths = cfg.get_value("progress", "total_deaths", 0)
	highest_level = cfg.get_value("progress", "highest_level", 1)
	ship_damaged = cfg.get_value("progress", "ship_damaged", false)
	first_run = cfg.get_value("progress", "first_run", false)
	unlocked_stages = cfg.get_value("progress", "unlocked_stages", [1])
	stage_first_complete = cfg.get_value("progress", "stage_first_complete", [])
	stage6_timer_used = cfg.get_value("progress", "stage6_timer_used", false)

	selected_race_id = cfg.get_value("player", "selected_race_id", 0)
	selected_ship_id = cfg.get_value("player", "selected_ship_id", 1)
	player_name = cfg.get_value("player", "player_name", "")

	unlocked_ships = cfg.get_value("ships", "unlocked_ships", [])
	upgraded_ships = cfg.get_value("ships", "upgraded_ships", {})

	research_progress = cfg.get_value("research", "research_progress", {})

	equipment_inventory = cfg.get_value("equipment", "equipment_inventory", [])
	equipped_weapons = cfg.get_value("equipment", "equipped_weapons", {})
	equipped_armor = cfg.get_value("equipment", "equipped_armor", {})

	if not equipment_inventory is Array:
		push_warning("[GameState] equipment_inventory corrupted, resetting")
		equipment_inventory = []

	print("[GameState] Loaded from slot %d: %s" % [slot_idx, path])
	_migrate_equipped_armor_to_array()
	return true

func reset_for_new_run() -> void:
	pre_run_coin = star_coin
	pre_run_minerals_total = minerals_low + minerals_mid + minerals_high
	pre_run_minerals_low = minerals_low
	pre_run_minerals_mid = minerals_mid
	pre_run_minerals_high = minerals_high

func reset_all_data() -> void:
	star_coin = 10_000_000
	minerals_low = 200_000
	minerals_mid = 200_000
	minerals_high = 200_000
	ship_damaged = false
	total_kills = 0
	total_deaths = 0
	highest_level = 1
	first_run = true
	last_run_reason = ""
	selected_race_id = 0
	player_name = ""
	selected_ship_id = 1
	unlocked_ships = []
	equipment_inventory = []
	equipped_weapons = {}
	equipped_armor = {}
	upgraded_ships = {}
	research_progress = {}
	unlocked_stages = [1]
	stage_first_complete = []
	stage6_timer_used = false
	pre_run_coin = star_coin
	pre_run_minerals_total = minerals_low + minerals_mid + minerals_high
	pre_run_minerals_low = minerals_low
	pre_run_minerals_mid = minerals_mid
	pre_run_minerals_high = minerals_high

func get_repair_cost() -> int:
	var ship = ShipData.get_ship(selected_ship_id)
	if ship:
		return ship.repair_cost
	if selected_ship_id == 0:
		var frigate = ShipData.get_ship(ShipData.ShipID.FRIGATE)
		return frigate.repair_cost if frigate else 500
	return 500

func can_afford_repair() -> bool:
	return star_coin >= get_repair_cost()

func repair_ship() -> bool:
	if not ship_damaged:
		return false
	if star_coin < get_repair_cost():
		return false
	star_coin -= get_repair_cost()
	ship_damaged = false
	if current_save_slot >= 0:
		save_save_slot(current_save_slot)
	else:
		save_game()
	return true

func add_rewards(coin: int, minrl_low: int, minrl_mid: int, minrl_high: int) -> void:
	star_coin += coin
	minerals_low += minrl_low
	minerals_mid += minrl_mid
	minerals_high += minrl_high
	if current_save_slot >= 0:
		save_save_slot(current_save_slot)
	else:
		save_game()

func on_run_started() -> void:
	if first_run:
		first_run = false
	pre_run_coin = star_coin
	pre_run_minerals_total = minerals_low + minerals_mid + minerals_high
	pre_run_minerals_low = minerals_low
	pre_run_minerals_mid = minerals_mid
	pre_run_minerals_high = minerals_high

func on_run_ended(kills: int, level: int, coin_gained: int,
		minerals_low: int, minerals_mid: int, minerals_high: int,
		was_dead: bool, run_reason: String = "") -> void:
	total_kills += kills
	highest_level = max(highest_level, level)
	if was_dead:
		total_deaths += 1
		ship_damaged = true
		var dead_coins = int(coin_gained * 0.5)
		var dead_low = int(minerals_low * 0.5)
		var dead_mid = int(minerals_mid * 0.5)
		var dead_high = int(minerals_high * 0.5)
		add_rewards(dead_coins, dead_low, dead_mid, dead_high)
	else:
		add_rewards(coin_gained, minerals_low, minerals_mid, minerals_high)
		if run_reason == "timeout":
			unlock_next_stage(selected_stage_id)
		elif is_stage_first_complete(selected_stage_id):
			unlock_next_stage(selected_stage_id)
	if run_reason == "timeout" and selected_stage_id == 6:
		stage6_timer_used = true
		save_game()

func get_earned_coin() -> int:
	return star_coin - pre_run_coin

func get_earned_minerals() -> int:
	return (minerals_low + minerals_mid + minerals_high) - pre_run_minerals_total

func reset_progress() -> void:
	star_coin = 10000000
	minerals_low = 10000
	minerals_mid = 10000
	minerals_high = 10000
	ship_damaged = false
	total_kills = 0
	total_deaths = 0
	highest_level = 1
	first_run = true
	last_run_reason = ""
	unlocked_stages = [1]
	stage6_timer_used = false
	selected_race_id = 0
	selected_ship_id = 1
	unlocked_ships = []
	equipment_inventory = []
	equipped_weapons = {}
	equipped_armor = {}
	upgraded_ships = {}
	if current_save_slot >= 0:
		save_save_slot(current_save_slot)
	else:
		save_game()

func is_stage_unlocked(stage_id: int) -> bool:
	return unlocked_stages.has(stage_id)

func is_stage_first_complete(stage_id: int) -> bool:
	return stage_first_complete.has(stage_id)

func unlock_next_stage(current_stage_id: int) -> void:
	var next_stage = current_stage_id + 1
	if next_stage <= 6 and not unlocked_stages.has(next_stage):
		unlocked_stages.append(next_stage)
		_debug("Unlocked stage: %d" % next_stage)
		save_game()

func _migrate_equipped_armor_to_array() -> void:
	for ship_id in equipped_armor.keys():
		var val = equipped_armor[ship_id]
		if val is Dictionary:
			equipped_armor[ship_id] = [val]
			print("[GameState] Migrated equipped_armor[%d] from Dictionary to Array" % ship_id)
		elif not (val is Array):
			equipped_armor[ship_id] = []
			push_warning("[GameState] equipped_armor[%d] had invalid type, reset to []" % ship_id)
