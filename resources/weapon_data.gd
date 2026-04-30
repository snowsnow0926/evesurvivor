class_name WeaponData
extends Resource

enum WeaponID { MISSILE, CANNON, RAILGUN, LASER, SMALL_MISSILE, SMALL_CANNON, SMALL_RAILGUN, SMALL_LASER }

@export var weapon_id: WeaponID
@export var display_name: String
@export var scene_path: String
@export var damage: float
@export var fire_interval: float
@export var projectile_speed: float
@export var range: float
@export var crit_rate: float
@export var crit_mult: float
@export var exclusive_upgrades: Array

static func get_weapon(weapon_id: WeaponID) -> WeaponData:
	match weapon_id:
		WeaponID.MISSILE:
			return _missile_data()
		WeaponID.CANNON:
			return _cannon_data()
		WeaponID.RAILGUN:
			return _railgun_data()
		WeaponID.LASER:
			return _laser_data()
		WeaponID.SMALL_MISSILE:
			return _small_missile_data()
		WeaponID.SMALL_CANNON:
			return _small_cannon_data()
		WeaponID.SMALL_RAILGUN:
			return _small_railgun_data()
		WeaponID.SMALL_LASER:
			return _small_laser_data()
		_:
			return _missile_data()

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
	w.damage = 12.0
	w.fire_interval = 2.5
	w.projectile_speed = 0.0
	w.range = 700.0
	w.crit_rate = 0.08
	w.crit_mult = 1.6
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
	w.display_name = "小型激光束"
	w.scene_path = "res://scenes/LaserBeam.tscn"
	w.damage = 10.0
	w.fire_interval = 2.5
	w.projectile_speed = 0.0
	w.range = 700.0
	w.crit_rate = 0.08
	w.crit_mult = 1.6
	w.exclusive_upgrades = [
		{"id": "laser_duration", "name": "高能光束", "desc": "激光持续时间 +20%", "max": 3},
		{"id": "laser_width", "name": "高效射击", "desc": "激光宽度 +20%", "max": 3},
		{"id": "laser_shield", "name": "护盾中和", "desc": "激光对护盾伤害 +20%", "max": 3},
	]
	return w

static func get_all_weapon_ids() -> Array[WeaponID]:
	return [WeaponID.MISSILE, WeaponID.CANNON, WeaponID.RAILGUN, WeaponID.LASER,
		WeaponID.SMALL_MISSILE, WeaponID.SMALL_CANNON, WeaponID.SMALL_RAILGUN, WeaponID.SMALL_LASER]
