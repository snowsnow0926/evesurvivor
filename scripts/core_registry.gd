extends Node

## 核心元数据中心 — 提供核心模板只读查询

const CoreEntry = preload("res://resources/core_entry.gd")
const CoreDefinitions = preload("res://resources/core_definitions.gd")

func _ready() -> void:
	# 预热模板缓存
	CoreEntry.get_all_templates()


func get_core_entry(core_id: String) -> CoreEntry:
	var templates = CoreEntry.get_all_templates()
	return templates.get(core_id)


func get_all_cores() -> Array:
	var templates = CoreEntry.get_all_templates()
	return templates.values()


func get_race_core(race: String) -> CoreEntry:
	var templates = CoreEntry.get_all_templates()
	for entry in templates.values():
		if entry.race == race:
			return entry
	return null


func get_core_id_by_race(race: String) -> String:
	var entry = get_race_core(race)
	return entry.core_id if entry else ""
