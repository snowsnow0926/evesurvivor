class_name StageData
extends Resource

enum StageType { NORMAL, BOSS_ONLY }

class StageInfo:
	var id: int
	var name: String
	var type: StageType
	var strength_mult: float
	var density_mult: float
	var boss_count: int
	var has_timer: bool
	var description: String

	static func normal(id: int, name: String, strength: float, density: float, has_timer: bool = false) -> StageInfo:
		var s := StageInfo.new()
		s.id = id
		s.name = name
		s.type = StageType.NORMAL
		s.strength_mult = strength
		s.density_mult = density
		s.boss_count = 1
		s.has_timer = has_timer
		s.description = "强度 %.2fx | 密度 %.2fx" % [strength, density]
		return s

	static func boss_only(id: int, name: String, strength: float, density: float, has_timer: bool = false) -> StageInfo:
		var s := StageInfo.new()
		s.id = id
		s.name = name
		s.type = StageType.BOSS_ONLY
		s.strength_mult = strength
		s.density_mult = density
		s.boss_count = 5
		s.has_timer = has_timer
		s.description = "纯BOSS关 | 强度 %.2fx | 密度 %.2fx" % [strength, density]
		return s

class ChapterInfo:
	var id: int
	var name: String
	var description: String
	var stages: Array[StageInfo]

	func _init(p_id: int, p_name: String, p_desc: String) -> void:
		id = p_id
		name = p_name
		description = p_desc
		stages = []

var _chapters: Array[ChapterInfo] = []

func _init() -> void:
	_setup_chapters()

func _setup_chapters() -> void:
	var chapter1 := ChapterInfo.new(1, "黑渊之地", "第一大关 — 黑渊之地")
	var stage_strengths := [1.0, 1.5, 2.25, 3.38, 5.06, 5.06]
	for i in range(6):
		var stage_id := i + 1
		var name := "第%d关" % stage_id
		var strength: float = stage_strengths[i]
		var density: float = stage_strengths[i]
		if stage_id < 6:
			chapter1.stages.append(StageInfo.normal(stage_id, name, strength, density))
		else:
			chapter1.stages.append(StageInfo.boss_only(stage_id, name, strength, density))
	_chapters.append(chapter1)

static func get_chapter(chapter_id: int) -> ChapterInfo:
	var inst := StageData.new() as StageData
	for ch in inst._chapters:
		if ch.id == chapter_id:
			return ch
	return null

static func get_all_chapters() -> Array:
	var inst := StageData.new() as StageData
	return inst._chapters

static func get_stage(chapter_id: int, stage_id: int) -> StageInfo:
	var chapter := get_chapter(chapter_id)
	if chapter == null:
		return null
	for s in chapter.stages:
		if s.id == stage_id:
			return s
	return null

static func calc_enemy_stats(base_hp: float, base_damage: float, base_speed: float, base_interval: float, stage: StageInfo, player_level: int) -> Dictionary:
	var level_bonus := 1.0 + 0.3 * (player_level - 1)
	var final_strength := stage.strength_mult * level_bonus
	var final_density := stage.density_mult * level_bonus
	return {
		"hp": base_hp * final_strength,
		"damage": base_damage * final_strength,
		"speed": base_speed * (1.0 + (final_strength - 1.0) * 0.2),
		"spawn_interval": base_interval / final_density,
		"boss_count": stage.boss_count,
		"is_boss_only": stage.type == StageType.BOSS_ONLY,
		"has_timer": stage.has_timer,
	}
