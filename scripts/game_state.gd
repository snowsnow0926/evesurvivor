extends Node

var selected_race_id: int = 0
var player_name: String = ""
var selected_ship_id: int = 1  # 默认护卫舰，避免与0值混淆
var unlocked_ships: Array = []
var unlocked_chapters: Array = [1]  # 默认章节1始终解锁
var unlocked_stages: Dictionary = {}  # {chapter_id: [stage_ids unlocked]}
var cleared_stages: Dictionary = {}  # {chapter_id: [stage_ids first-cleared]}
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
var selected_chapter_id: int = 1
var selected_stage_id: int = 1

const SAVE_PATH := "user://game_save.cfg"
const SAVE_SLOTS := 3
const DEBUG := false

var current_save_slot: int = 0  # 默认存档位 0，避免 -1 导致存档路径错误

func _debug(msg: String) -> void:
	if DEBUG:
		print("[GameState] ", msg)

func _migrate_armor_data(raw) -> Dictionary:
	if raw is Dictionary:
		var migrated: Dictionary = {}
		for ship_id in raw:
			var val = raw[ship_id]
			if val is Array:
				migrated[ship_id] = val
			elif val is Dictionary:
				if not val.is_empty():
					migrated[ship_id] = [val]
				else:
					migrated[ship_id] = []
			else:
				migrated[ship_id] = []
		return migrated
	return {}

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
	cfg.set_value("progress", "unlocked_chapters", unlocked_chapters)
	cfg.set_value("progress", "unlocked_stages", unlocked_stages)
	cfg.set_value("progress", "cleared_stages", cleared_stages)

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
	unlocked_chapters = cfg.get_value("progress", "unlocked_chapters", [1]) as Array
	unlocked_stages = cfg.get_value("progress", "unlocked_stages", {}) as Dictionary
	cleared_stages = cfg.get_value("progress", "cleared_stages", {}) as Dictionary

	selected_race_id = cfg.get_value("player", "selected_race_id", 0)
	selected_ship_id = cfg.get_value("player", "selected_ship_id", 1)
	player_name = cfg.get_value("player", "player_name", "")

	unlocked_ships = cfg.get_value("ships", "unlocked_ships", []) as Array
	upgraded_ships = cfg.get_value("ships", "upgraded_ships", {}) as Dictionary

	equipment_inventory = cfg.get_value("equipment", "equipment_inventory", []) as Array
	equipped_weapons = cfg.get_value("equipment", "equipped_weapons", {}) as Dictionary
	equipped_armor = _migrate_armor_data(cfg.get_value("equipment", "equipped_armor", {}) as Dictionary)

	print("[GameState] Game loaded from ", SAVE_PATH)
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
	cfg.set_value("progress", "unlocked_chapters", unlocked_chapters)
	cfg.set_value("progress", "unlocked_stages", unlocked_stages)
	cfg.set_value("progress", "cleared_stages", cleared_stages)

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
	# Set current_save_slot BEFORE loading, so _ready() picks the right path
	current_save_slot = slot_idx
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
	unlocked_chapters = cfg.get_value("progress", "unlocked_chapters", [1]) as Array
	unlocked_stages = cfg.get_value("progress", "unlocked_stages", {}) as Dictionary
	cleared_stages = cfg.get_value("progress", "cleared_stages", {}) as Dictionary

	selected_race_id = cfg.get_value("player", "selected_race_id", 0)
	selected_ship_id = cfg.get_value("player", "selected_ship_id", 1)
	player_name = cfg.get_value("player", "player_name", "")

	unlocked_ships = cfg.get_value("ships", "unlocked_ships", []) as Array
	upgraded_ships = cfg.get_value("ships", "upgraded_ships", {}) as Dictionary

	research_progress = cfg.get_value("research", "research_progress", {}) as Dictionary

	equipment_inventory = cfg.get_value("equipment", "equipment_inventory", []) as Array
	equipped_weapons = cfg.get_value("equipment", "equipped_weapons", {}) as Dictionary
	equipped_armor = _migrate_armor_data(cfg.get_value("equipment", "equipped_armor", {}) as Dictionary)

	print("[GameState] Loaded from slot %d: %s" % [slot_idx, path])
	return true

func reset_for_new_run() -> void:
	pre_run_coin = star_coin
	pre_run_minerals_total = minerals_low + minerals_mid + minerals_high

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
	unlocked_chapters = [1]
	unlocked_stages = {}
	cleared_stages = {}
	equipment_inventory = []
	equipped_weapons = {}
	equipped_armor = {}
	upgraded_ships = {}
	research_progress = {}
	pre_run_coin = star_coin
	pre_run_minerals_total = minerals_low + minerals_mid + minerals_high

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

func add_rewards(coin: int, minrl: int) -> void:
	star_coin += coin
	var low = int(minrl * 0.6)
	var mid = int(minrl * 0.3)
	var high = minrl - low - mid
	minerals_low += low
	minerals_mid += mid
	minerals_high += high
	if current_save_slot >= 0:
		save_save_slot(current_save_slot)
	else:
		save_game()

func on_run_started() -> void:
	if first_run:
		first_run = false
	pre_run_coin = star_coin
	pre_run_minerals_total = minerals_low + minerals_mid + minerals_high

func on_run_ended(kills: int, level: int, coin_gained: int, minerals_gained: int, was_dead: bool) -> void:
	total_kills += kills
	highest_level = max(highest_level, level)
	if was_dead:
		total_deaths += 1
		ship_damaged = true
		var dead_coins = int(coin_gained * 0.5)
		var dead_minerals = int(minerals_gained * 0.5)
		add_rewards(dead_coins, dead_minerals)
	else:
		add_rewards(coin_gained, minerals_gained)

func get_earned_coin() -> int:
	return star_coin - pre_run_coin

func get_earned_minerals() -> int:
	return (minerals_low + minerals_mid + minerals_high) - pre_run_minerals_total

func is_chapter_unlocked(chapter_id: int) -> bool:
	return unlocked_chapters.has(chapter_id)

func unlock_chapter(chapter_id: int) -> void:
	if not unlocked_chapters.has(chapter_id):
		unlocked_chapters.append(chapter_id)
		print("[GameState] Chapter %d unlocked!" % chapter_id)
		if current_save_slot >= 0:
			save_save_slot(current_save_slot)
		else:
			save_game()

func is_stage_unlocked(chapter_id: int, stage_id: int) -> bool:
	if not unlocked_chapters.has(chapter_id):
		return false
	if chapter_id == 1 and stage_id == 1:
		return true
	return unlocked_stages.get(chapter_id, []).has(stage_id)

func unlock_stage(chapter_id: int, stage_id: int) -> bool:
	if not is_stage_unlocked(chapter_id, stage_id):
		if not unlocked_stages.has(chapter_id):
			unlocked_stages[chapter_id] = []
		if not unlocked_stages[chapter_id].has(stage_id):
			unlocked_stages[chapter_id].append(stage_id)
			print("[GameState] Stage %d-%d unlocked!" % [chapter_id, stage_id])
			if current_save_slot >= 0:
				save_save_slot(current_save_slot)
			else:
				save_game()
			return true
	return false

func is_stage_cleared(chapter_id: int, stage_id: int) -> bool:
	return cleared_stages.get(chapter_id, []).has(stage_id)

func clear_stage(chapter_id: int, stage_id: int) -> bool:
	if not is_stage_cleared(chapter_id, stage_id):
		if not cleared_stages.has(chapter_id):
			cleared_stages[chapter_id] = []
		if not cleared_stages[chapter_id].has(stage_id):
			cleared_stages[chapter_id].append(stage_id)
			print("[GameState] Stage %d-%d cleared (first clear)!" % [chapter_id, stage_id])
			if current_save_slot >= 0:
				save_save_slot(current_save_slot)
			else:
				save_game()
			return true
	return false

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
	selected_race_id = 0
	selected_ship_id = 1
	unlocked_ships = []
	unlocked_chapters = [1]
	unlocked_stages = {}
	cleared_stages = {}
	equipment_inventory = []
	equipped_weapons = {}
	equipped_armor = {}
	upgraded_ships = {}
	if current_save_slot >= 0:
		save_save_slot(current_save_slot)
	else:
		save_game()
