extends Node

## BOSS注册中心。所有BOSS的元数据在此集中管理。
## 通过 Autoload "BossRegistry" 全局访问。
## 使用方法：
##   var entry = BossRegistry.get_chapter_boss(2)
##   var scene = BossRegistry.get_boss_scene("boss_void")

var _boss_entries: Dictionary = {}
var _chapter_boss_map: Dictionary = {}
var _chapter_stage_boss_map: Dictionary = {}

signal encounter_ready(boss_entry: BossEntry)

func _ready() -> void:
	_register_all_bosses()


func _register_all_bosses() -> void:
	# === 虚空领主 ===
	var void_entry := BossEntry.new(
		"boss_void",
		"虚空领主",
		"Boss Void",
		"boss_void",
		"",
		1,
		"boss",
		Color(0.5, 0.0, 0.5),
		Color(1.0, 0.2, 0.2),
		Color(0.5, 0.0, 0.5, 1.0),
		1.2,
		102.0,
		3.0,
		0.6,
		40.0,
		15.0,
		0.5,
		80.0,
		"res://scenes/BossBullet.tscn",
		400.0,
		10.0,
		40,
		5,
		1.0,
		100.0,
		300.0,
		5.0,
		15.0,
		10
	)
	_register_boss(void_entry)
	_chapter_boss_map[1] = "boss_void"

	# === 冲三杀手 ===
	var chongsan_entry := BossEntry.new(
		"boss_chongsan",
		"冲三杀手",
		"Boss Chongsan",
		"boss_chongsan",
		"",
		1,
		"boss",
		Color(0.0, 0.8, 0.8),
		Color(1.0, 0.5, 0.0),
		Color(0.0, 0.8, 0.8, 1.0),
		1.2,
		102.0,
		3.0,
		0.5,
		40.0,
		20.0,
		0.5,
		100.0,
		"res://scenes/BossBullet.tscn",
		380.0,
		8.0,
		40,
		5,
		1.0,
		120.0,
		350.0,
		5.0,
		15.0,
		12
	)
	_register_boss(chongsan_entry)
	_chapter_stage_boss_map["1_5"] = "boss_chongsan"
	# 默认章节BOSS：stage映射未覆盖时回退到此
	_chapter_boss_map[1] = "boss_void"

# ============================================================
#  Public API
# ============================================================

func get_boss_entry(boss_id: String) -> BossEntry:
	return _boss_entries.get(boss_id)


func get_chapter_boss(chapter_id: int) -> BossEntry:
	var boss_id = _chapter_boss_map.get(chapter_id, "boss_void")
	return get_boss_entry(boss_id)


func get_chapter_stage_boss(chapter_id: int, stage_id: int) -> BossEntry:
	var key := str(chapter_id) + "_" + str(stage_id)
	var boss_id = _chapter_stage_boss_map.get(key)
	if boss_id != null:
		return get_boss_entry(boss_id)
	return get_chapter_boss(chapter_id)


func get_chapter_stage_boss_scene(chapter_id: int, stage_id: int) -> PackedScene:
	var entry = get_chapter_stage_boss(chapter_id, stage_id)
	if entry == null:
		push_error("[BossRegistry] Chapter %d Stage %d has no boss registered." % [chapter_id, stage_id])
		return load("res://scenes/BossVoid.tscn") as PackedScene
	return get_boss_scene(entry.boss_id)


func get_boss_scene(boss_id: String) -> PackedScene:
	var entry = get_boss_entry(boss_id)
	if entry == null:
		push_error("[BossRegistry] Unknown boss_id: " + boss_id)
		return load("res://scenes/BossVoid.tscn") as PackedScene
	return _load_boss_scene(entry)


func get_chapter_boss_scene(chapter_id: int) -> PackedScene:
	var entry = get_chapter_boss(chapter_id)
	if entry == null:
		push_error("[BossRegistry] Chapter " + str(chapter_id) + " has no boss registered.")
		return load("res://scenes/BossVoid.tscn") as PackedScene
	return _load_boss_scene(entry)


func get_all_boss_ids() -> Array:
	return _boss_entries.keys()


func get_all_chapters() -> Array:
	return _chapter_boss_map.keys()


func get_boss_id(chapter_id: int) -> String:
	return _chapter_boss_map.get(chapter_id, "boss_void")


func get_chapter_stage_boss_id(chapter_id: int, stage_id: int) -> String:
	var key := str(chapter_id) + "_" + str(stage_id)
	var boss_id = _chapter_stage_boss_map.get(key)
	return boss_id if boss_id != null else get_boss_id(chapter_id)


# ============================================================
#  Internal
# ============================================================

func _register_boss(entry: BossEntry) -> void:
	if entry.boss_id == "":
		push_error("[BossRegistry] Cannot register boss with empty boss_id.")
		return
	if _boss_entries.has(entry.boss_id):
		push_error("[BossRegistry] Duplicate boss_id: " + entry.boss_id)
		return
	_boss_entries[entry.boss_id] = entry


func _load_boss_scene(entry: BossEntry) -> PackedScene:
	var scene_path := _get_scene_path_for_boss(entry.boss_id)
	if not ResourceLoader.exists(scene_path):
		push_error("[BossRegistry] Boss scene not found: " + scene_path + " (boss_id: " + entry.boss_id + ")")
		return load("res://scenes/BossVoid.tscn") as PackedScene
	return load(scene_path) as PackedScene


func _get_scene_path_for_boss(boss_id: String) -> String:
	match boss_id:
		"boss_void":      return "res://scenes/BossVoid.tscn"
		"boss_chongsan":   return "res://scenes/BossChongsan.tscn"
		"boss_qianpojun":  return "res://scenes/BossQianpojun.tscn"
		"boss_zhouyi":    return "res://scenes/BossZhouyi.tscn"
		"boss_wusong":    return "res://scenes/BossWusong.tscn"
		"boss_xueche":    return "res://scenes/BossXueche.tscn"
		"boss_final":     return "res://scenes/BossFinal.tscn"
	return "res://scenes/BossVoid.tscn"
