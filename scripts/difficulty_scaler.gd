class_name DifficultyScaler
extends Node

## Manages combo system and enemy difficulty scaling.
## Difficulty scales every 20 kills: HP ×1.10, damage ×1.10, speed +1.5%, spawn interval -0.1s.

var combo_count: int = 0
var combo_timer: float = 0.0
var combo_timeout: float = 3.0
var combo_multiplier: float = 1.0

var _difficulty_tier: int = 0       # 累计难度层数（每20击杀+1）
var _spawn_manager: Node = null

# === 难度递进参数 ===
const HP_SCALE_PER_TIER: float = 1.10       # 每层 HP ×1.10（+10%）
const DMG_SCALE_PER_TIER: float = 1.10       # 每层 伤害 ×1.10（+10%）
const SPEED_SCALE_PER_TIER: float = 1.015   # 每层 移速 ×1.015（+1.5%）
const SPAWN_INTERVAL_DECAY: float = 0.1     # 每层 生成间隔 -0.1s
const MIN_SPAWN_INTERVAL: float = 0.1       # 生成间隔下限

# === 内部缓存（避免每帧重复计算） ===
var _cached_strength: float = 1.0
var _cached_speed_mult: float = 1.0
var _cached_spawn_interval: float = 2.0

func setup(spawn_mgr: Node) -> void:
	_spawn_manager = spawn_mgr
	reset()

func setup_stage(stage_strength: float, stage_density: float, player_level: int) -> void:
	combo_count = 0
	combo_timer = 0.0
	combo_multiplier = 1.0
	# stage_density 作为初始生成间隔基准
	if _spawn_manager:
		var base_interval: float = 2.0 / stage_density
		_cached_spawn_interval = base_interval
		_spawn_manager.update_spawn_interval(_cached_spawn_interval)
	_recalculate()

func update_combo(delta: float) -> void:
	if combo_count > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0
			combo_multiplier = _get_combo_multiplier()

func on_enemy_killed() -> void:
	combo_count += 1
	combo_timer = combo_timeout
	combo_multiplier = _get_combo_multiplier()

func on_difficulty_tick() -> void:
	_difficulty_tier += 1
	_recalculate()
	print("[难度提升] 第 %d 层: strength=%.3f speed=%.3f interval=%.2fs" % [_difficulty_tier, _cached_strength, _cached_speed_mult, _cached_spawn_interval])

func _recalculate() -> void:
	# HP/Damage 倍率
	_cached_strength = pow(HP_SCALE_PER_TIER, _difficulty_tier)
	# 移速倍率
	_cached_speed_mult = pow(SPEED_SCALE_PER_TIER, _difficulty_tier)
	# 生成间隔（从当前间隔递减，不从基础值重置）
	_cached_spawn_interval = maxf(MIN_SPAWN_INTERVAL, _cached_spawn_interval - SPAWN_INTERVAL_DECAY * _difficulty_tier)

	if _spawn_manager:
		_spawn_manager.update_spawn_interval(_cached_spawn_interval)

func _get_combo_multiplier() -> float:
	if combo_count >= 30:
		return 3.0
	elif combo_count >= 20:
		return 2.5
	elif combo_count >= 10:
		return 2.0
	elif combo_count >= 5:
		return 1.5
	return 1.0

## 获取当前难度倍率（HP/Damage 用）
func get_strength_mult() -> float:
	return _cached_strength

## 获取当前移速倍率（额外加成，用于乘在基础移速上）
func get_speed_mult() -> float:
	return _cached_speed_mult

## 获取当前难度层数
func get_difficulty_tier() -> int:
	return _difficulty_tier

func reset() -> void:
	combo_count = 0
	combo_timer = 0.0
	combo_multiplier = 1.0
	_difficulty_tier = 0
	_cached_strength = 1.0
	_cached_speed_mult = 1.0
	_cached_spawn_interval = 2.0
