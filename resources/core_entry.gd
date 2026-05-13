class_name CoreEntry
extends RefCounted

## 单个核心的模板数据

var core_id: String
var core_name_zh: String
var core_name_en: String
var race: String
var icon_id: String

# 每个核心有5个词条：3个种族专属 + 2个通用
var race_skills: Array = []
var universal_skills: Array = []

# 种族词条初始等级=1，通用词条初始等级=0
const RACE_SKILL_START_LEVEL: int = 1
const UNIVERSAL_SKILL_START_LEVEL: int = 0

# 核心最大等级：局内6级 + 局外扩展2级 = 最高8级
const MAX_IN_GAME_LEVEL: int = 6
const MAX_EXTENDED_LEVEL: int = 8


## 获取该核心所有词条ID列表
func get_all_skill_ids() -> Array:
	var all: Array = []
	all.append_array(race_skills)
	all.append_array(universal_skills)
	return all


## 获取初始等级
func get_start_level(skill_id: String) -> int:
	if race_skills.has(skill_id):
		return RACE_SKILL_START_LEVEL
	return UNIVERSAL_SKILL_START_LEVEL


## 创建核心模板
static func _create_core(id: String, name_zh: String, name_en: String,
		r: String, icon: String,
		race_s: Array, universal_s: Array) -> CoreEntry:
	var entry = CoreEntry.new()
	entry.core_id = id
	entry.core_name_zh = name_zh
	entry.core_name_en = name_en
	entry.race = r
	entry.icon_id = icon
	entry.race_skills = race_s
	entry.universal_skills = universal_s
	return entry


## 所有核心模板（静态字典）
static func get_all_templates() -> Dictionary:
	if _core_templates.is_empty():
		_core_templates["core_missile"] = _create_core(
			"core_missile", "导弹核心", "Missile Core",
			"human",
			"core_missile",
			["fire_coverage", "silent_hunter", "precision_kill"],
			["damage", "shield_max"]
		)
		_core_templates["core_cannon"] = _create_core(
			"core_cannon", "加农核心", "Cannon Core",
			"orc",
			"core_cannon",
			["cannon_bloodthirst", "cannon_rush", "cannon_vengeance"],
			["damage", "shield_regen"]
		)
		_core_templates["core_railgun"] = _create_core(
			"core_railgun", "磁轨核心", "Railgun Core",
			"plant",
			"core_railgun",
			["railgun_damage", "railgun_crit", "railgun_multi"],
			["damage", "shield_max"]
		)
		_core_templates["core_laser"] = _create_core(
			"core_laser", "激光核心", "Laser Core",
			"silicon",
			"core_laser",
			["laser_duration", "laser_width", "laser_shield"],
			["damage", "shield_regen"]
		)
	return _core_templates


static var _core_templates: Dictionary = {}
