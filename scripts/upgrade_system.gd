class_name UpgradeSystem
extends Node

## Manages the upgrade pool, upgrade counts, and application of upgrade effects.

signal upgrade_applied()
signal upgrade_requested()

var player_stats: PlayerStats

var upgrade_counts: Dictionary = {}
var upgrade_pool: Array = []
var _research_bonus_counts: Dictionary = {}
var _race_talent_counts: Dictionary = {}

func _init(ps: PlayerStats) -> void:
	player_stats = ps
	_setup_upgrade_pool()

func _setup_upgrade_pool() -> void:
	upgrade_pool = [
		{"id": "damage", "name": "伤害强化", "desc": "所有武器伤害 x1.2", "max": 3, "weight": "high"},
		{"id": "shield_max", "name": "临时护盾", "desc": "shield_max +30，立即补满", "max": 3, "weight": "mid"},
		{"id": "fire_coverage", "name": "火力覆盖", "desc": "导弹哒哒哒连射（Lv.1=2发/Lv.2=3发/Lv.3=4发）", "max": 3, "weight": "high"},
		{"id": "shield_regen", "name": "护盾充能", "desc": "shield_regen x1.5", "max": 3, "weight": "mid"},
		{"id": "silent_hunter", "name": "静默猎手", "desc": "静止时射速+15%（fire_interval x0.85）", "max": 3, "weight": "low"},
		{"id": "precision_kill", "name": "精准猎杀", "desc": "导弹索敌范围 +100", "max": 3, "weight": "low"},
		{"id": "cannon_bloodthirst", "name": "嗜血残暴", "desc": "单次加农炮子弹数量 +1", "max": 3, "weight": "mid"},
		{"id": "cannon_rush", "name": "狂飙突进", "desc": "移动时射速 +15%", "max": 3, "weight": "low"},
		{"id": "cannon_vengeance", "name": "为了部落", "desc": "受伤时射速 +15%，持续2秒", "max": 3, "weight": "low"},
		{"id": "railgun_damage", "name": "一发入魂", "desc": "磁轨炮伤害 +20%", "max": 3, "weight": "low"},
		{"id": "railgun_crit", "name": "命中注定", "desc": "磁轨炮暴击率 +10%", "max": 3, "weight": "low"},
		{"id": "railgun_multi", "name": "多重射击", "desc": "单次射击次数 +1", "max": 3, "weight": "low"},
		{"id": "laser_duration", "name": "高能光束", "desc": "激光持续时间 +20%", "max": 3, "weight": "mid"},
		{"id": "laser_width", "name": "高效射击", "desc": "激光宽度 +20%", "max": 3, "weight": "low"},
		{"id": "laser_shield", "name": "护盾中和", "desc": "激光对护盾伤害 +20%", "max": 3, "weight": "low"},
	]

func apply_upgrade(upgrade_id: String) -> bool:
	if not upgrade_counts.has(upgrade_id):
		upgrade_counts[upgrade_id] = 0

	var upgrade_data = upgrade_pool.filter(func(u): return u["id"] == upgrade_id)
	if upgrade_data.is_empty():
		return false

	var data = upgrade_data[0]
	var research_bonus = _research_bonus_counts.get(upgrade_id, 0)
	var race_bonus = _race_talent_counts.get(upgrade_id, 0)
	var effective_max = data["max"] + research_bonus + race_bonus
	if upgrade_counts[upgrade_id] >= effective_max:
		return false

	upgrade_counts[upgrade_id] += 1
	player_stats.apply_upgrade(upgrade_id)
	upgrade_applied.emit()
	return true

func trigger_upgrade_request() -> void:
	upgrade_requested.emit()

func get_available_upgrades() -> Array:
	return upgrade_pool

func reset() -> void:
	upgrade_counts = {}
	_research_bonus_counts = {}
	_race_talent_counts = {}
	_setup_upgrade_pool()

func apply_research_bonuses() -> void:
	if GameState.research_progress.is_empty():
		return
	for upgrade_id in GameState.research_progress:
		var bonus_level = GameState.research_progress[upgrade_id]
		if bonus_level <= 0:
			continue
		_research_bonus_counts[upgrade_id] = bonus_level
		for i in range(bonus_level):
			player_stats._apply_upgrade_effect(upgrade_id)
			upgrade_counts[upgrade_id] = upgrade_counts.get(upgrade_id, 0) + 1

func apply_race_talent(upgrade_id: String, level: int = 1) -> void:
	if level <= 0:
		return
	for i in range(level):
		player_stats._apply_upgrade_effect(upgrade_id)
		upgrade_counts[upgrade_id] = upgrade_counts.get(upgrade_id, 0) + 1
	_race_talent_counts[upgrade_id] = _race_talent_counts.get(upgrade_id, 0) + level
