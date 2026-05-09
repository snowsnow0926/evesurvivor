extends Node

const SAVE_VERSION := 2
const SAVE_SLOTS := 3
const SLOT_AUTO := 3
const DEBUG := false

var current_save_slot: int = 0
var pending_new_game_slot: int = -1

var selected_race_id: int = 0
var player_name: String = ""
var selected_ship_id: int = 1
var unlocked_ships: Array = []
var unlocked_chapters: Array = [1]
var unlocked_stages: Dictionary = {}
var cleared_stages: Dictionary = {}
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
var progress_text: String = ""
var first_run: bool = true
var last_run_reason: String = ""
var pre_run_coin: int = 0
var pre_run_minerals_total: int = 0
var selected_chapter_id: int = 1
var selected_stage_id: int = 1

func _debug(msg: String) -> void:
	if DEBUG:
		print("[GameState] ", msg)

func _compute_progress_text() -> String:
	if unlocked_stages.is_empty():
		return "第1章·第1关"
	return _compute_progress_from_dict(unlocked_stages)

static func _compute_progress_from_dict(stages_dict: Dictionary) -> String:
	if stages_dict.is_empty():
		return "第1章·第1关"
	var max_chapter := 1
	var max_stage := 0
	for chapter_id in stages_dict:
		var ch = int(chapter_id)
		if ch > max_chapter:
			max_chapter = ch
		var stages: Array = stages_dict[chapter_id]
		for stage_id in stages:
			var st = int(stage_id)
			if ch == max_chapter and st > max_stage:
				max_stage = st
	if max_stage == 0:
		max_stage = 1
	return "第%d章·第%d关" % [max_chapter, max_stage]

func _ready() -> void:
	load_game()

func _resolve_path(slot: int) -> String:
	return "user://save_slot_%d.cfg" % slot

func _collect_save_data() -> Dictionary:
	return {
		"meta": {
			"version": SAVE_VERSION,
			"saved_at": Time.get_datetime_string_from_system(),
		},
		"progress": {
			"star_coin": star_coin,
			"minerals_low": minerals_low,
			"minerals_mid": minerals_mid,
			"minerals_high": minerals_high,
			"total_kills": total_kills,
			"total_deaths": total_deaths,
			"highest_level": highest_level,
			"progress_text": _compute_progress_text(),
			"ship_damaged": ship_damaged,
			"first_run": first_run,
			"unlocked_chapters": unlocked_chapters,
			"unlocked_stages": unlocked_stages,
			"cleared_stages": cleared_stages,
		},
		"player": {
			"selected_race_id": selected_race_id,
			"selected_ship_id": selected_ship_id,
			"player_name": player_name,
		},
		"ships": {
			"unlocked_ships": unlocked_ships,
			"upgraded_ships": upgraded_ships,
		},
		"research": {
			"research_progress": research_progress,
		},
		"equipment": {
			"equipment_inventory": equipment_inventory,
			"equipped_weapons": equipped_weapons,
			"equipped_armor": equipped_armor,
		},
	}

func _apply_save_data(data: Dictionary) -> void:
	var version = data.get("meta", {}).get("version", 1)
	data = _migrate_data(version, data)

	var progress = data.get("progress", {})
	star_coin = progress.get("star_coin", 0)
	minerals_low = progress.get("minerals_low", 0)
	minerals_mid = progress.get("minerals_mid", 0)
	minerals_high = progress.get("minerals_high", 0)
	total_kills = progress.get("total_kills", 0)
	total_deaths = progress.get("total_deaths", 0)
	highest_level = progress.get("highest_level", 1)
	progress_text = progress.get("progress_text", "")
	ship_damaged = progress.get("ship_damaged", false)
	first_run = progress.get("first_run", true)
	unlocked_chapters = progress.get("unlocked_chapters", [1]) as Array
	unlocked_stages = progress.get("unlocked_stages", {}) as Dictionary
	cleared_stages = progress.get("cleared_stages", {}) as Dictionary
	if progress_text.is_empty():
		progress_text = _compute_progress_text()

	var player = data.get("player", {})
	selected_race_id = player.get("selected_race_id", 0)
	selected_ship_id = player.get("selected_ship_id", 1)
	player_name = player.get("player_name", "")

	var ships = data.get("ships", {})
	unlocked_ships = ships.get("unlocked_ships", []) as Array
	upgraded_ships = ships.get("upgraded_ships", {}) as Dictionary

	var research = data.get("research", {})
	research_progress = research.get("research_progress", {}) as Dictionary

	var equipment = data.get("equipment", {})
	equipment_inventory = equipment.get("equipment_inventory", []) as Array
	equipped_weapons = equipment.get("equipped_weapons", {}) as Dictionary
	equipped_armor = _migrate_armor_data(equipment.get("equipped_armor", {}) as Dictionary)

func _migrate_data(from_version: int, data: Dictionary) -> Dictionary:
	var v = from_version
	if v < 2:
		data = _migrate_v1_to_v2(data)
		v = 2
	data["meta"] = data.get("meta", {})
	data["meta"]["version"] = SAVE_VERSION
	return data

func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	if data.has("equipment"):
		var eq = data["equipment"]
		if eq.has("equipped_armor"):
			eq["equipped_armor"] = _migrate_armor_data(eq["equipped_armor"])
	return data

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

func save(slot: int = -1) -> bool:
	var target_slot = slot if slot >= 0 else SLOT_AUTO
	var cfg = ConfigFile.new()
	var save_data = _collect_save_data()

	cfg.set_value("meta", "version", save_data["meta"]["version"])
	cfg.set_value("meta", "saved_at", save_data["meta"]["saved_at"])

	var progress = save_data["progress"]
	for key in progress:
		cfg.set_value("progress", key, progress[key])

	var player = save_data["player"]
	for key in player:
		cfg.set_value("player", key, player[key])

	var ships = save_data["ships"]
	for key in ships:
		cfg.set_value("ships", key, ships[key])

	var research = save_data["research"]
	for key in research:
		cfg.set_value("research", key, research[key])

	var equipment = save_data["equipment"]
	for key in equipment:
		cfg.set_value("equipment", key, equipment[key])

	var path = _resolve_path(target_slot)
	var err = cfg.save(path)
	if err != OK:
		push_error("[GameState] Save failed (slot %d): error %d" % [target_slot, err])
		return false
	print("[GameState] Saved to slot %d: %s" % [target_slot, path])
	return true

func _do_load(slot: int = -1) -> bool:
	var target_slot = slot if slot >= 0 else SLOT_AUTO
	var path = _resolve_path(target_slot)
	if not FileAccess.file_exists(path):
		if slot < 0:
			print("[GameState] No save file found, starting fresh")
			return false
		print("[GameState] No save file for slot %d, trying legacy path" % target_slot)
		return _do_load(-1)

	var cfg = ConfigFile.new()
	var err = cfg.load(path)
	if err != OK:
		push_error("[GameState] Load failed (slot %d): error %d" % [slot, err])
		return false

	var raw_data: Dictionary = {
		"meta": {},
		"progress": {},
		"player": {},
		"ships": {},
		"research": {},
		"equipment": {},
	}

	for key in cfg.get_section_keys("meta"):
		raw_data["meta"][key] = cfg.get_value("meta", key)
	for key in cfg.get_section_keys("progress"):
		raw_data["progress"][key] = cfg.get_value("progress", key)
	for key in cfg.get_section_keys("player"):
		raw_data["player"][key] = cfg.get_value("player", key)
	for key in cfg.get_section_keys("ships"):
		raw_data["ships"][key] = cfg.get_value("ships", key)
	for key in cfg.get_section_keys("research"):
		raw_data["research"][key] = cfg.get_value("research", key)
	for key in cfg.get_section_keys("equipment"):
		raw_data["equipment"][key] = cfg.get_value("equipment", key)

	_apply_save_data(raw_data)
	print("[GameState] Loaded from slot %d: %s" % [target_slot, path])
	return true

func save_game() -> bool:
	return save(current_save_slot)

func load_game() -> bool:
	return _do_load(SLOT_AUTO)

func auto_save() -> bool:
	return save(SLOT_AUTO)

func load_auto_save() -> bool:
	return _do_load(SLOT_AUTO)

func load_save_slot(slot_idx: int) -> bool:
	current_save_slot = slot_idx
	return _do_load(slot_idx)

func save_save_slot(slot_idx: int) -> bool:
	return save(slot_idx)

func delete_save() -> void:
	var path = _resolve_path(current_save_slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("[GameState] Save file deleted: ", path)

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
	current_save_slot = SLOT_AUTO
	var auto_path = _resolve_path(SLOT_AUTO)
	if FileAccess.file_exists(auto_path):
		DirAccess.remove_absolute(auto_path)
		print("[GameState] Auto save file deleted: ", auto_path)

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
	auto_save()
	return true

func add_rewards(coin: int, minrl: int) -> void:
	star_coin += coin
	var low = int(minrl * 0.6)
	var mid = int(minrl * 0.3)
	var high = minrl - low - mid
	minerals_low += low
	minerals_mid += mid
	minerals_high += high
	auto_save()

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
		auto_save()

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
			auto_save()
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
			auto_save()
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
	auto_save()
