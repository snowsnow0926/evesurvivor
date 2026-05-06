class_name StageData
extends Resource

enum StageType { NORMAL, BOSS_ONLY }

class ToncalStats:
	var hp: float
	var shield: float
	var damage: float
	var speed: float
	var explosion_damage: float
	var explosion_speed: float

	func _init(
		p_hp: float, p_shield: float, p_damage: float, p_speed: float,
		p_exp_damage: float = 0.0, p_exp_speed: float = 0.0
	) -> void:
		hp = p_hp
		shield = p_shield
		damage = p_damage
		speed = p_speed
		explosion_damage = p_exp_damage
		explosion_speed = p_exp_speed

enum LootTier { LOW, MEDIUM, HIGH }

class LootProfile:
	var coin_melee: int
	var coin_sentry: int
	var coin_raven: int
	var coin_boss: int
	var mineral_melee: int
	var mineral_sentry: int
	var mineral_raven: int
	var mineral_boss: int
	var mineral_tier_melee: LootTier
	var mineral_tier_sentry: LootTier
	var mineral_tier_raven: LootTier
	var mineral_tier_boss: LootTier
	var equipment_tier: int
	var drop_rate: float
	var quality_weights: Array

	func _init(
		p_cm: int, p_cs: int, p_cr: int, p_cb: int,
		p_mm: int, p_ms: int, p_mr: int, p_mb: int,
		p_mt_m: LootTier, p_mt_s: LootTier, p_mt_r: LootTier, p_mt_b: LootTier,
		p_eq_tier: int, p_drop_rate: float,
		p_qw: Array
	) -> void:
		coin_melee = p_cm
		coin_sentry = p_cs
		coin_raven = p_cr
		coin_boss = p_cb
		mineral_melee = p_mm
		mineral_sentry = p_ms
		mineral_raven = p_mr
		mineral_boss = p_mb
		mineral_tier_melee = p_mt_m
		mineral_tier_sentry = p_mt_s
		mineral_tier_raven = p_mt_r
		mineral_tier_boss = p_mt_b
		equipment_tier = p_eq_tier
		drop_rate = p_drop_rate
		quality_weights = p_qw

	func get_coin(enemy_type: String) -> int:
		match enemy_type:
			"melee": return coin_melee
			"sentry": return coin_sentry
			"raven": return coin_raven
			"boss": return coin_boss
		return coin_melee

	func get_mineral(enemy_type: String) -> int:
		match enemy_type:
			"melee": return mineral_melee
			"sentry": return mineral_sentry
			"raven": return mineral_raven
			"boss": return mineral_boss
		return mineral_melee

	func get_mineral_tier(enemy_type: String) -> LootTier:
		match enemy_type:
			"melee": return mineral_tier_melee
			"sentry": return mineral_tier_sentry
			"raven": return mineral_tier_raven
			"boss": return mineral_tier_boss
		return mineral_tier_melee

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
	var melee_stats: ToncalStats
	var sentry_stats: ToncalStats
	var raven_stats: ToncalStats
	var boss_stats: ToncalStats
	var loot_profile: LootProfile

	func _init(p_id: int, p_name: String, p_desc: String) -> void:
		id = p_id
		name = p_name
		description = p_desc
		stages = []

var _chapters: Array[ChapterInfo] = []

func _init() -> void:
	_setup_chapters()

func _setup_chapters() -> void:
	# 黑渊之地 — 第一大关
	var chapter1 := ChapterInfo.new(1, "黑渊之地", "第一大关 — 黑渊之地")
	chapter1.melee_stats = ToncalStats.new(30.0, 10.0, 10.0, 120.0)
	chapter1.sentry_stats = ToncalStats.new(20.0, 7.0, 8.0, 90.0)
	chapter1.raven_stats = ToncalStats.new(15.0, 5.0, 25.0, 220.0, 25.0, 220.0)
	chapter1.boss_stats = ToncalStats.new(500.0, 167.0, 15.0, 80.0)
	chapter1.loot_profile = LootProfile.new(
		10, 14, 18, 250,
		2, 3, 4, 40,
		LootTier.LOW, LootTier.LOW, LootTier.LOW, LootTier.LOW,
		0, 0.02,
		[0.60, 0.30, 0.10, 0.00, 0.00]
	)
	var stage_strengths := [1.0, 1.5, 2.25, 3.38, 5.06, 5.06]
	for i in range(6):
		var stage_id := i + 1
		var name := "第%d关" % stage_id
		var strength: float = stage_strengths[i]
		var density: float = stage_strengths[i]
		var is_last_stage := (stage_id == 6)
		if not is_last_stage:
			chapter1.stages.append(StageInfo.normal(stage_id, name, strength, density, true))
		else:
			chapter1.stages.append(StageInfo.boss_only(stage_id, name, strength, density, true))
	_chapters.append(chapter1)

	# 婓德之境 — 第二大关
	var chapter2 := ChapterInfo.new(2, "婓德之境", "第二大关 — 婓德之境 | 巡洋舰级别")
	chapter2.melee_stats = ToncalStats.new(55.0, 18.0, 18.0, 105.0)
	chapter2.sentry_stats = ToncalStats.new(38.0, 13.0, 14.0, 80.0)
	chapter2.raven_stats = ToncalStats.new(28.0, 9.0, 40.0, 200.0, 40.0, 200.0)
	chapter2.boss_stats = ToncalStats.new(900.0, 300.0, 28.0, 70.0)
	chapter2.loot_profile = LootProfile.new(
		20, 28, 36, 500,
		4, 6, 8, 80,
		LootTier.LOW, LootTier.LOW, LootTier.LOW, LootTier.LOW,
		1, 0.02,
		[0.50, 0.35, 0.15, 0.00, 0.00]
	)
	var stage_strengths2 := [1.0, 1.5, 2.25, 3.38, 5.06, 5.06]
	for i in range(6):
		var stage_id := i + 1
		var name := "第%d关" % stage_id
		var strength: float = stage_strengths2[i]
		var density: float = stage_strengths2[i]
		var is_last_stage := (stage_id == 6)
		if not is_last_stage:
			chapter2.stages.append(StageInfo.normal(stage_id, name, strength, density, true))
		else:
			chapter2.stages.append(StageInfo.boss_only(stage_id, name, strength, density, true))
	_chapters.append(chapter2)

	# 德克廉深渊 — 第三大关
	var chapter3 := ChapterInfo.new(3, "德克廉深渊", "第三大关 — 德克廉深渊 | 战列巡洋舰级别")
	chapter3.melee_stats = ToncalStats.new(90.0, 30.0, 28.0, 90.0)
	chapter3.sentry_stats = ToncalStats.new(65.0, 22.0, 22.0, 70.0)
	chapter3.raven_stats = ToncalStats.new(45.0, 15.0, 60.0, 180.0, 60.0, 180.0)
	chapter3.boss_stats = ToncalStats.new(1500.0, 500.0, 45.0, 60.0)
	chapter3.loot_profile = LootProfile.new(
		35, 50, 65, 900,
		3, 5, 7, 60,
		LootTier.MEDIUM, LootTier.MEDIUM, LootTier.MEDIUM, LootTier.MEDIUM,
		1, 0.02,
		[0.30, 0.40, 0.25, 0.05, 0.00]
	)
	var stage_strengths3 := [1.0, 1.5, 2.25, 3.38, 5.06, 5.06]
	for i in range(6):
		var stage_id := i + 1
		var name := "第%d关" % stage_id
		var strength: float = stage_strengths3[i]
		var density: float = stage_strengths3[i]
		var is_last_stage := (stage_id == 6)
		if not is_last_stage:
			chapter3.stages.append(StageInfo.normal(stage_id, name, strength, density, true))
		else:
			chapter3.stages.append(StageInfo.boss_only(stage_id, name, strength, density, true))
	_chapters.append(chapter3)

	# 特布特前线 — 第四大关
	var chapter4 := ChapterInfo.new(4, "特布特前线", "第四大关 — 特布特前线 | 战列舰级别")
	chapter4.melee_stats = ToncalStats.new(150.0, 50.0, 42.0, 75.0)
	chapter4.sentry_stats = ToncalStats.new(110.0, 37.0, 34.0, 60.0)
	chapter4.raven_stats = ToncalStats.new(75.0, 25.0, 90.0, 160.0, 90.0, 160.0)
	chapter4.boss_stats = ToncalStats.new(2500.0, 833.0, 70.0, 50.0)
	chapter4.loot_profile = LootProfile.new(
		60, 85, 110, 1500,
		5, 8, 11, 100,
		LootTier.MEDIUM, LootTier.MEDIUM, LootTier.MEDIUM, LootTier.MEDIUM,
		2, 0.02,
		[0.15, 0.30, 0.35, 0.15, 0.05]
	)
	var stage_strengths4 := [1.0, 1.5, 2.25, 3.38, 5.06, 5.06]
	for i in range(6):
		var stage_id := i + 1
		var name := "第%d关" % stage_id
		var strength: float = stage_strengths4[i]
		var density: float = stage_strengths4[i]
		var is_last_stage := (stage_id == 6)
		if not is_last_stage:
			chapter4.stages.append(StageInfo.normal(stage_id, name, strength, density, true))
		else:
			chapter4.stages.append(StageInfo.boss_only(stage_id, name, strength, density, true))
	_chapters.append(chapter4)

	# 维纳尔混乱之地 — 第五大关
	var chapter5 := ChapterInfo.new(5, "维纳尔混乱之地", "第五大关 — 维纳尔混乱之地 | 无畏舰级别")
	chapter5.melee_stats = ToncalStats.new(250.0, 83.0, 65.0, 60.0)
	chapter5.sentry_stats = ToncalStats.new(180.0, 60.0, 52.0, 50.0)
	chapter5.raven_stats = ToncalStats.new(120.0, 40.0, 135.0, 140.0, 135.0, 140.0)
	chapter5.boss_stats = ToncalStats.new(4000.0, 1333.0, 110.0, 40.0)
	chapter5.loot_profile = LootProfile.new(
		100, 140, 180, 2500,
		3, 5, 7, 60,
		LootTier.HIGH, LootTier.HIGH, LootTier.HIGH, LootTier.HIGH,
		3, 0.02,
		[0.05, 0.15, 0.35, 0.30, 0.15]
	)
	var stage_strengths5 := [1.0, 1.5, 2.25, 3.38, 5.06, 5.06]
	for i in range(6):
		var stage_id := i + 1
		var name := "第%d关" % stage_id
		var strength: float = stage_strengths5[i]
		var density: float = stage_strengths5[i]
		var is_last_stage := (stage_id == 6)
		if not is_last_stage:
			chapter5.stages.append(StageInfo.normal(stage_id, name, strength, density, true))
		else:
			chapter5.stages.append(StageInfo.boss_only(stage_id, name, strength, density, true))
	_chapters.append(chapter5)

	# 血脉死域 — 第六大关
	var chapter6 := ChapterInfo.new(6, "血脉死域", "第六大关 — 血脉死域 | 随机混合")
	chapter6.melee_stats = ToncalStats.new(0.0, 0.0, 0.0, 0.0)
	chapter6.sentry_stats = ToncalStats.new(0.0, 0.0, 0.0, 0.0)
	chapter6.raven_stats = ToncalStats.new(0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
	chapter6.boss_stats = ToncalStats.new(0.0, 0.0, 0.0, 0.0)
	var stage_strengths6 := [1.0, 1.5, 2.25, 3.38, 5.06, 5.06]
	for i in range(6):
		var stage_id := i + 1
		var name := "第%d关" % stage_id
		var strength: float = stage_strengths6[i]
		var density: float = stage_strengths6[i]
		var is_last_stage := (stage_id == 6)
		if not is_last_stage:
			chapter6.stages.append(StageInfo.normal(stage_id, name, strength, density, true))
		else:
			chapter6.stages.append(StageInfo.boss_only(stage_id, name, strength, density, true))
	_chapters.append(chapter6)

static func get_chapter(chapter_id: int) -> ChapterInfo:
	var inst := StageData.new() as StageData
	for ch in inst._chapters:
		if ch.id == chapter_id:
			return ch
	return null

static func get_chapter_stats(chapter_id: int, enemy_type: String) -> ToncalStats:
	var ch := get_chapter(chapter_id)
	if ch == null:
		return ToncalStats.new(30.0, 10.0, 10.0, 100.0)
	match enemy_type:
		"melee": return ch.melee_stats
		"sentry": return ch.sentry_stats
		"raven": return ch.raven_stats
		"boss": return ch.boss_stats
	return ToncalStats.new(30.0, 10.0, 10.0, 100.0)

static func get_random_tonnage_stats(enemy_type: String) -> ToncalStats:
	var tonnage_chapter := (randi() % 5) + 1
	return get_chapter_stats(tonnage_chapter, enemy_type)

static func get_random_tonnage_chapter() -> int:
	return (randi() % 5) + 1

static func get_chapter_loot(chapter_id: int) -> LootProfile:
	var ch := get_chapter(chapter_id)
	if ch != null and ch.loot_profile != null:
		return ch.loot_profile
	return LootProfile.new(10, 14, 18, 250, 2, 3, 4, 40, LootTier.LOW, LootTier.LOW, LootTier.LOW, LootTier.LOW, 0, 0.02, [0.60, 0.30, 0.10, 0.00, 0.00])

static func get_tonnage_loot(chapter_id: int) -> LootProfile:
	return get_chapter_loot(chapter_id)

static func get_random_tonnage_loot() -> LootProfile:
	return get_chapter_loot(get_random_tonnage_chapter())

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
