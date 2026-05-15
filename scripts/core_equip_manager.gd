extends Node

## 核心装备管理器 — 管理所有核心数据、局内升级、效果同步

signal skill_upgraded(core_id: String, skill_id: String, new_level: int)
signal core_equipped(core_id: String)
signal core_unequipped(core_id: String)

const CoreEntry = preload("res://resources/core_entry.gd")
const CoreDefinitions = preload("res://resources/core_definitions.gd")

# === 核心数据存储 ===
var _cores: Dictionary = {}       # { core_id: CoreData }
var _equipped_core_id: String = ""
# V2.3: 核心总经验池（跨局永久累加，用于未来能量球系统）
static var _total_core_xp: int = 0

# V2.3: 核心升级经验曲线（1小时≈2400经验升满5词条×6级）
const CORE_XP_CURVE: Array[int] = [30, 50, 80, 120, 200]  # Lv1→2,2→3,3→4,4→5,5→6

# V2.3: 添加核心总经验（跨局累加）
func add_xp(amount: int) -> void:
	_total_core_xp += maxi(amount, 0)

func get_total_xp() -> int:
	return _total_core_xp

func set_total_xp(v: int) -> void:
	_total_core_xp = maxi(v, 0)


# === CoreData 内嵌类 ===
class CoreData extends RefCounted:
	var core_id: String = ""
	var skill_levels: Dictionary = {}  # { skill_id: int level }
	var is_unlocked: bool = false
	var skill_extra_max: Dictionary = {}  # { skill_id: int 局外升级扩展的额外上限 }

	func to_dict() -> Dictionary:
		return {
			"core_id": core_id,
			"skill_levels": skill_levels.duplicate(true),
			"is_unlocked": is_unlocked,
			"skill_extra_max": skill_extra_max.duplicate(true),
		}

	static func from_dict(d: Dictionary) -> CoreData:
		var cd = CoreData.new()
		cd.core_id = d.get("core_id", "")
		if d.get("skill_levels") is Dictionary:
			cd.skill_levels = d["skill_levels"].duplicate(true)
		else:
			cd.skill_levels = {}
		cd.is_unlocked = d.get("is_unlocked", false)
		if d.get("skill_extra_max") is Dictionary:
			cd.skill_extra_max = d["skill_extra_max"].duplicate(true)
		else:
			cd.skill_extra_max = {}
		return cd


# ================================================================
# 公开 API
# ================================================================

func get_equipped_core_id() -> String:
	return _equipped_core_id


func get_core_data(core_id: String) -> CoreData:
	return _cores.get(core_id)


func is_core_unlocked(core_id: String) -> bool:
	var cd = _cores.get(core_id)
	return cd != null and cd.is_unlocked


func is_core_equipped(core_id: String) -> bool:
	return _equipped_core_id == core_id and is_core_unlocked(core_id)


# === 核心显示名 ===
func get_display_name(core_id: String) -> String:
	var entry = CoreRegistry.get_core_entry(core_id)
	if not entry:
		return core_id
	var total = _get_total_upgrade_count(core_id)
	if total == 0:
		return entry.core_name_zh
	return entry.core_name_zh + "+" + str(total)


func _get_total_upgrade_count(core_id: String) -> int:
	var cd = _cores.get(core_id)
	if not cd:
		return 0
	var entry = CoreRegistry.get_core_entry(core_id)
	if not entry:
		return 0
	# 总等级 = sum(skill_levels) - 种族词条初始等级总和(3)
	var sum_levels = 0
	for skill_id in cd.skill_levels:
		sum_levels += cd.skill_levels[skill_id]
	# 种族词条初始=1，共3个，所以扣3
	return maxi(sum_levels - 3, 0)


# === 开局自动装备核心 ===
func equip_starting_core(race: String) -> void:
	var core_id = CoreRegistry.get_core_id_by_race(race)
	if core_id.is_empty():
		push_warning("[CoreEquipManager] No core found for race: " + race)
		return

	# 如果核心未解锁，先解锁
	if not _cores.has(core_id) or not _cores[core_id].is_unlocked:
		unlock_core(core_id)

	# 装备
	_equipped_core_id = core_id
	core_equipped.emit(core_id)


# === 手动装备/拆卸 ===
func equip_core(core_id: String) -> bool:
	if not is_core_unlocked(core_id):
		return false
	if _equipped_core_id == core_id:
		return true
	_equipped_core_id = core_id
	core_equipped.emit(core_id)
	return true


func unequip_core() -> void:
	var prev = _equipped_core_id
	_equipped_core_id = ""
	if not prev.is_empty():
		core_unequipped.emit(prev)


# === 解锁核心（用于掉落/购买） ===
func unlock_core(core_id: String) -> bool:
	if not _cores.has(core_id):
		_cores[core_id] = CoreData.new()
	var cd = _cores[core_id]
	if cd.is_unlocked:
		return false
	cd.core_id = core_id
	cd.is_unlocked = true

	# 初始化词条等级
	var entry = CoreRegistry.get_core_entry(core_id)
	if entry:
		for skill_id in entry.get_all_skill_ids():
			if not cd.skill_levels.has(skill_id):
				cd.skill_levels[skill_id] = entry.get_start_level(skill_id)
	return true


# ================================================================
# 局内三选一升级（由 upgrade_menu 调用）
# ================================================================

func get_skill_level(core_id: String, skill_id: String) -> int:
	var cd = _cores.get(core_id)
	if not cd:
		return 0
	return cd.skill_levels.get(skill_id, 0)


func get_skill_max_level(core_id: String, skill_id: String) -> int:
	# 局内6级封顶，局外升级会直接修改 skill_levels 到 6
	return CoreEntry.MAX_IN_GAME_LEVEL


func get_available_upgrades(core_id: String) -> Array:
	# 返回当前核心中所有可升级词条（level < max_level）
	var cd = _cores.get(core_id)
	if not cd:
		return []
	var entry = CoreRegistry.get_core_entry(core_id)
	if not entry:
		return []

	var result: Array = []
	for skill_id in entry.get_all_skill_ids():
		var current = cd.skill_levels.get(skill_id, 0)
		var max_lvl = get_skill_max_level(core_id, skill_id)
		if current < max_lvl:
			var level_desc = CoreDefinitions.get_skill_desc(skill_id, current + 1)
			result.append({
				"id": skill_id,
				"name": CoreDefinitions.get_skill_name(skill_id),
				"desc": level_desc,
				"color": CoreDefinitions.get_skill_color(skill_id),
				"current_level": current,
				"max_level": max_lvl,
			})
	return result


func upgrade_skill(core_id: String, skill_id: String) -> bool:
	var cd = _cores.get(core_id)
	if not cd:
		return false

	var current = cd.skill_levels.get(skill_id, 0)
	var max_lvl = get_skill_max_level(core_id, skill_id)
	if current >= max_lvl:
		return false

	cd.skill_levels[skill_id] = current + 1
	skill_upgraded.emit(core_id, skill_id, current + 1)
	return true


# ================================================================
# 局外核心升级中心（由 core_upgrade_center 调用）
# ================================================================

const LEVEL_UP_COSTS: Array = [
	{"coin": 100, "mineral": 100, "tier": "low"},   # 0→1
	{"coin": 150, "mineral": 150, "tier": "low"},   # 1→2
	{"coin": 200, "mineral": 200, "tier": "low"},   # 2→3
	{"coin": 250, "mineral": 250, "tier": "mid"},   # 3→4
	{"coin": 300, "mineral": 300, "tier": "mid"},  # 4→5
	{"coin": 400, "mineral": 400, "tier": "mid"},  # 5→6
]

func can_upgrade_skill_extra(core_id: String, skill_id: String) -> bool:
	var cd = _cores.get(core_id)
	if not cd:
		return false
	var current = cd.skill_levels.get(skill_id, 0)
	return current < CoreEntry.MAX_IN_GAME_LEVEL


func get_extra_level_cost(core_id: String, skill_id: String) -> Dictionary:
	var cd = _cores.get(core_id)
	var current = 0
	if cd:
		current = cd.skill_levels.get(skill_id, 0)
	# 每级消耗一个配置，LEVEL_UP_COSTS[0]=第1级(0→1)，[1]=第2级(1→2)
	if current >= LEVEL_UP_COSTS.size():
		return {}
	return LEVEL_UP_COSTS[current]


func upgrade_skill_extra(core_id: String, skill_id: String, coin_cost: int, mineral_cost: int, mineral_tier: String) -> bool:
	if GameState.star_coin < coin_cost:
		return false
	var mineral_amount = _get_mineral_amount(mineral_tier)
	if mineral_amount < mineral_cost:
		return false

	GameState.star_coin -= coin_cost
	_deduct_mineral(mineral_tier, mineral_cost)

	var cd = _cores.get(core_id)
	if not cd:
		return false

	var current = cd.skill_levels.get(skill_id, 0)
	var max_lvl = get_skill_max_level(core_id, skill_id)
	if current >= max_lvl:
		return false

	cd.skill_levels[skill_id] = current + 1
	skill_upgraded.emit(core_id, skill_id, current + 1)
	return true


func _get_mineral_amount(tier: String) -> int:
	match tier:
		"low":  return GameState.minerals_low
		"mid":  return GameState.minerals_mid
		"high": return GameState.minerals_high
	return 0


func _deduct_mineral(tier: String, amount: int) -> void:
	match tier:
		"low":  GameState.minerals_low -= amount
		"mid":  GameState.minerals_mid -= amount
		"high": GameState.minerals_high -= amount


# ================================================================
# 存档
# ================================================================

func save_to_dict() -> Dictionary:
	return {
		"cores": _cores.keys().map(func(k): return {"id": k, "data": _cores[k].to_dict()}),
		"equipped_core_id": _equipped_core_id,
		"total_core_xp": _total_core_xp,
	}


func load_from_dict(data: Dictionary) -> void:
	_cores.clear()
	_equipped_core_id = data.get("equipped_core_id", "")
	_total_core_xp = data.get("total_core_xp", 0)

	var cores_list: Array = data.get("cores", [])
	for entry_data in cores_list:
		var cid = entry_data.get("id", "")
		var cd_data: Dictionary = entry_data.get("data", {})
		if not cid.is_empty():
			_cores[cid] = CoreData.from_dict(cd_data)


func reset_for_new_run() -> void:
	# 局内升级数据不清空（局内升级随角色局内升级保留）
	pass


# ================================================================
# 获取核心总览信息（供UI使用）
# ================================================================

func get_all_cores_summary() -> Array:
	var result: Array = []
	var all_cores = CoreRegistry.get_all_cores()
	for entry in all_cores:
		result.append({
			"core_id": entry.core_id,
			"display_name": get_display_name(entry.core_id),
			"is_unlocked": is_core_unlocked(entry.core_id),
			"is_equipped": is_core_equipped(entry.core_id),
			"race": entry.race,
			"icon_id": entry.icon_id,
		})
	return result


func get_core_skill_detail(core_id: String) -> Array:
	var cd = _cores.get(core_id)
	var entry = CoreRegistry.get_core_entry(core_id)
	if not entry:
		return []

	var result: Array = []
	for skill_id in entry.get_all_skill_ids():
		var current = 0
		var max_lvl = CoreEntry.MAX_IN_GAME_LEVEL
		if cd:
			current = cd.skill_levels.get(skill_id, 0)
			max_lvl = get_skill_max_level(core_id, skill_id)
		result.append({
			"skill_id": skill_id,
			"name": CoreDefinitions.get_skill_name(skill_id),
			"color": CoreDefinitions.get_skill_color(skill_id),
			"desc": CoreDefinitions.get_skill_desc(skill_id, current),
			"current_level": current,
			"max_level": max_lvl,
			"is_race_skill": entry.race_skills.has(skill_id),
		})
	return result
