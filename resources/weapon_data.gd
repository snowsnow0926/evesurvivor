class_name WeaponData
extends Resource

enum WeaponID {
	MISSILE, CANNON, RAILGUN, LASER,
	SMALL_MISSILE, SMALL_CANNON, SMALL_RAILGUN, SMALL_LASER,
	MEDIUM_MISSILE, MEDIUM_CANNON, MEDIUM_RAILGUN, MEDIUM_LASER,
	LARGE_MISSILE, LARGE_CANNON, LARGE_RAILGUN, LARGE_LASER,
	FLAGSHIP_MISSILE, FLAGSHIP_CANNON, FLAGSHIP_RAILGUN, FLAGSHIP_LASER
}

@export var weapon_id: WeaponID
@export var display_name: String
@export var scene_path: String
@export var damage: float
@export var fire_interval: float
@export var projectile_speed: float
@export var range: float
@export var crit_rate: float
@export var crit_mult: float
@export var quality: int = 0
@export var exclusive_upgrades: Array
@export var beam_width: float = 0.0
@export var duration: float = 0.0

const EquipmentData = preload("res://resources/equipment_data.gd")

static var _base_cache: Dictionary = {}

static func _ensure_base_cache() -> void:
	if _base_cache.is_empty():
		_base_cache[WeaponID.MISSILE] = _missile_data()
		_base_cache[WeaponID.CANNON] = _cannon_data()
		_base_cache[WeaponID.RAILGUN] = _railgun_data()
		_base_cache[WeaponID.LASER] = _laser_data()
		_base_cache[WeaponID.SMALL_MISSILE] = _small_missile_data()
		_base_cache[WeaponID.SMALL_CANNON] = _small_cannon_data()
		_base_cache[WeaponID.SMALL_RAILGUN] = _small_railgun_data()
		_base_cache[WeaponID.SMALL_LASER] = _small_laser_data()
		_base_cache[WeaponID.MEDIUM_MISSILE] = _medium_missile_data()
		_base_cache[WeaponID.MEDIUM_CANNON] = _medium_cannon_data()
		_base_cache[WeaponID.MEDIUM_RAILGUN] = _medium_railgun_data()
		_base_cache[WeaponID.MEDIUM_LASER] = _medium_laser_data()
		_base_cache[WeaponID.LARGE_MISSILE] = _large_missile_data()
		_base_cache[WeaponID.LARGE_CANNON] = _large_cannon_data()
		_base_cache[WeaponID.LARGE_RAILGUN] = _large_railgun_data()
		_base_cache[WeaponID.LARGE_LASER] = _large_laser_data()
		_base_cache[WeaponID.FLAGSHIP_MISSILE] = _flagship_missile_data()
		_base_cache[WeaponID.FLAGSHIP_CANNON] = _flagship_cannon_data()
		_base_cache[WeaponID.FLAGSHIP_RAILGUN] = _flagship_railgun_data()
		_base_cache[WeaponID.FLAGSHIP_LASER] = _flagship_laser_data()

static func get_weapon(weapon_id: int, weapon_quality: int = 0) -> WeaponData:
	_ensure_base_cache()
	var base = _base_cache.get(weapon_id)
	if base == null:
		base = _base_cache[WeaponID.MISSILE]
	var copy = base.duplicate()
	copy.quality = weapon_quality
	var mult: float = EquipmentData.get_quality_mult(weapon_quality)
	copy.damage = base.damage * mult
	copy.range = base.range * mult
	return copy

static func _missile_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.MISSILE
	w.display_name = "导弹"
	w.scene_path = "res://scenes/Missile.tscn"
	w.damage = 15.0
	w.fire_interval = 0.8
	w.projectile_speed = 600.0
	w.range = 600.0
	w.crit_rate = 0.05
	w.crit_mult = 1.5
	w.exclusive_upgrades = [
		{"id": "fire_coverage", "name": "火力覆盖", "desc": "导弹分叉发射（Lv.1=2枚/Lv.2=3枚/Lv.3=4枚）", "max": 3},
		{"id": "silent_hunter", "name": "静默猎手", "desc": "静止时射速+15%（fire_interval x0.85）", "max": 3},
		{"id": "precision_kill", "name": "精准猎杀", "desc": "导弹索敌范围 +100", "max": 3},
	]
	return w

static func _cannon_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.CANNON
	w.display_name = "加农炮"
	w.scene_path = "res://scenes/CannonBullet.tscn"
	w.damage = 25.0
	w.fire_interval = 1.2
	w.projectile_speed = 800.0
	w.range = 400.0
	w.crit_rate = 0.03
	w.crit_mult = 1.2
	w.exclusive_upgrades = [
		{"id": "cannon_bloodthirst", "name": "嗜血残暴", "desc": "单次加农炮子弹数量 +1", "max": 3},
		{"id": "cannon_rush", "name": "狂飙突进", "desc": "移动时射速 +15%", "max": 3},
		{"id": "cannon_vengeance", "name": "为了部落", "desc": "受伤时射速 +15%，持续2秒", "max": 3},
	]
	return w

static func _railgun_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.RAILGUN
	w.display_name = "磁轨炮"
	w.scene_path = "res://scenes/RailgunBullet.tscn"
	w.damage = 30.0
	w.fire_interval = 0.6
	w.projectile_speed = 1000.0
	w.range = 400.0
	w.crit_rate = 0.35
	w.crit_mult = 1.5
	w.exclusive_upgrades = [
		{"id": "railgun_damage", "name": "一发入魂", "desc": "武器伤害 +20%", "max": 3},
		{"id": "railgun_crit", "name": "命中注定", "desc": "武器暴击率 +10%", "max": 3},
		{"id": "railgun_multi", "name": "多重射击", "desc": "单次射击次数 +1", "max": 3},
	]
	return w

static func _laser_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.LASER
	w.display_name = "激光炮"
	w.scene_path = "res://scenes/LaserBeam.tscn"
	w.damage = 28.0
	w.fire_interval = 2.4
	w.projectile_speed = 0.0
	w.range = 600.0
	w.crit_rate = 0.10
	w.crit_mult = 1.7
	w.beam_width = 24.0
	w.duration = 2.4
	w.exclusive_upgrades = [
		{"id": "laser_duration", "name": "高能光束", "desc": "激光持续时间 +20%", "max": 3},
		{"id": "laser_width", "name": "高效射击", "desc": "激光宽度 +20%", "max": 3},
		{"id": "laser_shield", "name": "护盾中和", "desc": "激光对护盾伤害 +20%", "max": 3},
	]
	return w

static func _small_missile_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.SMALL_MISSILE
	w.display_name = "小型导弹发射器"
	w.scene_path = "res://scenes/Missile.tscn"
	w.damage = 15.0
	w.fire_interval = 0.8
	w.projectile_speed = 600.0
	w.range = 600.0
	w.crit_rate = 0.05
	w.crit_mult = 1.5
	w.exclusive_upgrades = [
		{"id": "fire_coverage", "name": "火力覆盖", "desc": "导弹分叉发射（Lv.1=2枚/Lv.2=3枚/Lv.3=4枚）", "max": 3},
		{"id": "silent_hunter", "name": "静默猎手", "desc": "静止时射速+15%（fire_interval x0.85）", "max": 3},
		{"id": "precision_kill", "name": "精准猎杀", "desc": "导弹索敌范围 +100", "max": 3},
	]
	return w

static func _small_cannon_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.SMALL_CANNON
	w.display_name = "小型加农炮"
	w.scene_path = "res://scenes/CannonBullet.tscn"
	w.damage = 25.0
	w.fire_interval = 1.2
	w.projectile_speed = 800.0
	w.range = 400.0
	w.crit_rate = 0.03
	w.crit_mult = 1.2
	w.exclusive_upgrades = [
		{"id": "cannon_bloodthirst", "name": "嗜血残暴", "desc": "单次加农炮子弹数量 +1", "max": 3},
		{"id": "cannon_rush", "name": "狂飙突进", "desc": "移动时射速 +15%", "max": 3},
		{"id": "cannon_vengeance", "name": "为了部落", "desc": "受伤时射速 +15%，持续2秒", "max": 3},
	]
	return w

static func _small_railgun_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.SMALL_RAILGUN
	w.display_name = "小型磁轨炮"
	w.scene_path = "res://scenes/RailgunBullet.tscn"
	w.damage = 30.0
	w.fire_interval = 0.6
	w.projectile_speed = 1000.0
	w.range = 400.0
	w.crit_rate = 0.35
	w.crit_mult = 1.5
	w.exclusive_upgrades = [
		{"id": "railgun_damage", "name": "一发入魂", "desc": "武器伤害 +20%", "max": 3},
		{"id": "railgun_crit", "name": "命中注定", "desc": "武器暴击率 +10%", "max": 3},
		{"id": "railgun_multi", "name": "多重射击", "desc": "单次射击次数 +1", "max": 3},
	]
	return w

static func _small_laser_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.SMALL_LASER
	w.display_name = "小型激光炮"
	w.scene_path = "res://scenes/LaserBeam.tscn"
	w.damage = 20.0
	w.fire_interval = 2.0
	w.projectile_speed = 0.0
	w.range = 500.0
	w.crit_rate = 0.08
	w.crit_mult = 1.6
	w.beam_width = 20.0
	w.duration = 2.0
	w.exclusive_upgrades = [
		{"id": "laser_duration", "name": "高能光束", "desc": "激光持续时间 +20%", "max": 3},
		{"id": "laser_width", "name": "高效射击", "desc": "激光宽度 +20%", "max": 3},
		{"id": "laser_shield", "name": "护盾中和", "desc": "激光对护盾伤害 +20%", "max": 3},
	]
	return w

static func _medium_missile_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.MEDIUM_MISSILE
	w.display_name = "中型导弹发射器"
	w.scene_path = "res://scenes/Missile.tscn"
	w.damage = 25.0
	w.fire_interval = 1.0
	w.projectile_speed = 600.0
	w.range = 700.0
	w.crit_rate = 0.06
	w.crit_mult = 1.5
	w.exclusive_upgrades = [
		{"id": "fire_coverage", "name": "火力覆盖", "desc": "导弹分叉发射（Lv.1=2枚/Lv.2=3枚/Lv.3=4枚）", "max": 3},
		{"id": "silent_hunter", "name": "静默猎手", "desc": "静止时射速+15%（fire_interval x0.85）", "max": 3},
		{"id": "precision_kill", "name": "精准猎杀", "desc": "导弹索敌范围 +100", "max": 3},
	]
	return w

static func _medium_cannon_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.MEDIUM_CANNON
	w.display_name = "中型加农炮"
	w.scene_path = "res://scenes/CannonBullet.tscn"
	w.damage = 40.0
	w.fire_interval = 1.5
	w.projectile_speed = 800.0
	w.range = 500.0
	w.crit_rate = 0.04
	w.crit_mult = 1.3
	w.exclusive_upgrades = [
		{"id": "cannon_bloodthirst", "name": "嗜血残暴", "desc": "单次加农炮子弹数量 +1", "max": 3},
		{"id": "cannon_rush", "name": "狂飙突进", "desc": "移动时射速 +15%", "max": 3},
		{"id": "cannon_vengeance", "name": "为了部落", "desc": "受伤时射速 +15%，持续2秒", "max": 3},
	]
	return w

static func _medium_railgun_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.MEDIUM_RAILGUN
	w.display_name = "中型磁轨炮"
	w.scene_path = "res://scenes/RailgunBullet.tscn"
	w.damage = 50.0
	w.fire_interval = 0.8
	w.projectile_speed = 1000.0
	w.range = 500.0
	w.crit_rate = 0.38
	w.crit_mult = 1.6
	w.exclusive_upgrades = [
		{"id": "railgun_damage", "name": "一发入魂", "desc": "武器伤害 +20%", "max": 3},
		{"id": "railgun_crit", "name": "命中注定", "desc": "武器暴击率 +10%", "max": 3},
		{"id": "railgun_multi", "name": "多重射击", "desc": "单次射击次数 +1", "max": 3},
	]
	return w

static func _medium_laser_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.MEDIUM_LASER
	w.display_name = "中型激光炮"
	w.scene_path = "res://scenes/LaserBeam.tscn"
	w.damage = 40.0
	w.fire_interval = 2.8
	w.projectile_speed = 0.0
	w.range = 750.0
	w.crit_rate = 0.12
	w.crit_mult = 1.8
	w.beam_width = 30.0
	w.duration = 2.8
	w.exclusive_upgrades = [
		{"id": "laser_duration", "name": "高能光束", "desc": "激光持续时间 +20%", "max": 3},
		{"id": "laser_width", "name": "高效射击", "desc": "激光宽度 +20%", "max": 3},
		{"id": "laser_shield", "name": "护盾中和", "desc": "激光对护盾伤害 +20%", "max": 3},
	]
	return w

static func _large_missile_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.LARGE_MISSILE
	w.display_name = "大型导弹发射器"
	w.scene_path = "res://scenes/Missile.tscn"
	w.damage = 40.0
	w.fire_interval = 1.3
	w.projectile_speed = 600.0
	w.range = 800.0
	w.crit_rate = 0.07
	w.crit_mult = 1.6
	w.exclusive_upgrades = [
		{"id": "fire_coverage", "name": "火力覆盖", "desc": "导弹分叉发射（Lv.1=2枚/Lv.2=3枚/Lv.3=4枚）", "max": 3},
		{"id": "silent_hunter", "name": "静默猎手", "desc": "静止时射速+15%（fire_interval x0.85）", "max": 3},
		{"id": "precision_kill", "name": "精准猎杀", "desc": "导弹索敌范围 +100", "max": 3},
	]
	return w

static func _large_cannon_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.LARGE_CANNON
	w.display_name = "大型加农炮"
	w.scene_path = "res://scenes/CannonBullet.tscn"
	w.damage = 65.0
	w.fire_interval = 2.0
	w.projectile_speed = 800.0
	w.range = 600.0
	w.crit_rate = 0.05
	w.crit_mult = 1.4
	w.exclusive_upgrades = [
		{"id": "cannon_bloodthirst", "name": "嗜血残暴", "desc": "单次加农炮子弹数量 +1", "max": 3},
		{"id": "cannon_rush", "name": "狂飙突进", "desc": "移动时射速 +15%", "max": 3},
		{"id": "cannon_vengeance", "name": "为了部落", "desc": "受伤时射速 +15%，持续2秒", "max": 3},
	]
	return w

static func _large_railgun_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.LARGE_RAILGUN
	w.display_name = "大型磁轨炮"
	w.scene_path = "res://scenes/RailgunBullet.tscn"
	w.damage = 80.0
	w.fire_interval = 1.0
	w.projectile_speed = 1000.0
	w.range = 600.0
	w.crit_rate = 0.40
	w.crit_mult = 1.7
	w.exclusive_upgrades = [
		{"id": "railgun_damage", "name": "一发入魂", "desc": "武器伤害 +20%", "max": 3},
		{"id": "railgun_crit", "name": "命中注定", "desc": "武器暴击率 +10%", "max": 3},
		{"id": "railgun_multi", "name": "多重射击", "desc": "单次射击次数 +1", "max": 3},
	]
	return w

static func _large_laser_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.LARGE_LASER
	w.display_name = "大型激光炮"
	w.scene_path = "res://scenes/LaserBeam.tscn"
	w.damage = 55.0
	w.fire_interval = 3.2
	w.projectile_speed = 0.0
	w.range = 900.0
	w.crit_rate = 0.14
	w.crit_mult = 1.9
	w.beam_width = 38.0
	w.duration = 3.2
	w.exclusive_upgrades = [
		{"id": "laser_duration", "name": "高能光束", "desc": "激光持续时间 +20%", "max": 3},
		{"id": "laser_width", "name": "高效射击", "desc": "激光宽度 +20%", "max": 3},
		{"id": "laser_shield", "name": "护盾中和", "desc": "激光对护盾伤害 +20%", "max": 3},
	]
	return w

static func _flagship_missile_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.FLAGSHIP_MISSILE
	w.display_name = "旗舰级导弹发射器"
	w.scene_path = "res://scenes/Missile.tscn"
	w.damage = 65.0
	w.fire_interval = 1.6
	w.projectile_speed = 600.0
	w.range = 1000.0
	w.crit_rate = 0.08
	w.crit_mult = 1.7
	w.exclusive_upgrades = [
		{"id": "fire_coverage", "name": "火力覆盖", "desc": "导弹分叉发射（Lv.1=2枚/Lv.2=3枚/Lv.3=4枚）", "max": 3},
		{"id": "silent_hunter", "name": "静默猎手", "desc": "静止时射速+15%（fire_interval x0.85）", "max": 3},
		{"id": "precision_kill", "name": "精准猎杀", "desc": "导弹索敌范围 +100", "max": 3},
	]
	return w

static func _flagship_cannon_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.FLAGSHIP_CANNON
	w.display_name = "旗舰级加农炮"
	w.scene_path = "res://scenes/CannonBullet.tscn"
	w.damage = 100.0
	w.fire_interval = 2.5
	w.projectile_speed = 800.0
	w.range = 800.0
	w.crit_rate = 0.06
	w.crit_mult = 1.5
	w.exclusive_upgrades = [
		{"id": "cannon_bloodthirst", "name": "嗜血残暴", "desc": "单次加农炮子弹数量 +1", "max": 3},
		{"id": "cannon_rush", "name": "狂飙突进", "desc": "移动时射速 +15%", "max": 3},
		{"id": "cannon_vengeance", "name": "为了部落", "desc": "受伤时射速 +15%，持续2秒", "max": 3},
	]
	return w

static func _flagship_railgun_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.FLAGSHIP_RAILGUN
	w.display_name = "旗舰级磁轨炮"
	w.scene_path = "res://scenes/RailgunBullet.tscn"
	w.damage = 120.0
	w.fire_interval = 1.2
	w.projectile_speed = 1000.0
	w.range = 800.0
	w.crit_rate = 0.45
	w.crit_mult = 1.8
	w.exclusive_upgrades = [
		{"id": "railgun_damage", "name": "一发入魂", "desc": "武器伤害 +20%", "max": 3},
		{"id": "railgun_crit", "name": "命中注定", "desc": "武器暴击率 +10%", "max": 3},
		{"id": "railgun_multi", "name": "多重射击", "desc": "单次射击次数 +1", "max": 3},
	]
	return w

static func _flagship_laser_data() -> WeaponData:
	var w = WeaponData.new()
	w.weapon_id = WeaponID.FLAGSHIP_LASER
	w.display_name = "旗舰级激光炮"
	w.scene_path = "res://scenes/LaserBeam.tscn"
	w.damage = 75.0
	w.fire_interval = 3.8
	w.projectile_speed = 0.0
	w.range = 1050.0
	w.crit_rate = 0.16
	w.crit_mult = 2.0
	w.beam_width = 48.0
	w.duration = 3.8
	w.exclusive_upgrades = [
		{"id": "laser_duration", "name": "高能光束", "desc": "激光持续时间 +20%", "max": 3},
		{"id": "laser_width", "name": "高效射击", "desc": "激光宽度 +20%", "max": 3},
		{"id": "laser_shield", "name": "护盾中和", "desc": "激光对护盾伤害 +20%", "max": 3},
	]
	return w

static func get_all_weapon_ids() -> Array:
	return [
		WeaponID.MISSILE, WeaponID.CANNON, WeaponID.RAILGUN, WeaponID.LASER,
		WeaponID.SMALL_MISSILE, WeaponID.SMALL_CANNON, WeaponID.SMALL_RAILGUN, WeaponID.SMALL_LASER,
		WeaponID.MEDIUM_MISSILE, WeaponID.MEDIUM_CANNON, WeaponID.MEDIUM_RAILGUN, WeaponID.MEDIUM_LASER,
		WeaponID.LARGE_MISSILE, WeaponID.LARGE_CANNON, WeaponID.LARGE_RAILGUN, WeaponID.LARGE_LASER,
		WeaponID.FLAGSHIP_MISSILE, WeaponID.FLAGSHIP_CANNON, WeaponID.FLAGSHIP_RAILGUN, WeaponID.FLAGSHIP_LASER,
	]
