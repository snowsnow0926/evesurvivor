class_name RaceData
extends Resource

enum RaceID { HUMAN, ORC, PLANT, SILICON, DIVINE }

@export var race_id: RaceID
@export var display_name: String
@export var description: String
@export var base_hp: float
@export var shield_max: float
@export var shield_regen: float
@export var move_speed: float
@export var dodge_rate: float
@export var crit_rate: float
@export var crit_mult: float
@export var base_weapon_scene: String
@export var talents: Array

static func get_race(race_id: RaceID) -> RaceData:
	match race_id:
		RaceID.HUMAN:
			return _human_data()
		RaceID.ORC:
			return _orc_data()
		RaceID.PLANT:
			return _plant_data()
		RaceID.SILICON:
			return _silicon_data()
		_:
			return _human_data()

static func _human_data() -> RaceData:
	var r = RaceData.new()
	r.race_id = RaceID.HUMAN
	r.display_name = "人类"
	r.description = "均衡型种族，各项属性平衡，默认使用导弹武器。"
	r.base_hp = 100.0
	r.shield_max = 50.0
	r.shield_regen = 4.0
	r.move_speed = 320.0
	r.dodge_rate = 0.1
	r.crit_rate = 0.05
	r.crit_mult = 1.5
	r.base_weapon_scene = "res://scenes/Missile.tscn"
	r.talents = [
		{"name": "导弹专精", "desc": "导弹基础等级 +1", "type": "missile_base_level", "value": 1},
		{"name": "远程锁定", "desc": "导弹射程 +20%", "type": "missile_range", "value": 1},
	]
	return r

static func _orc_data() -> RaceData:
	var r = RaceData.new()
	r.race_id = RaceID.ORC
	r.display_name = "兽人"
	r.description = "重型战士，HP更高，默认使用加农炮武器，拥有炮术专精和狂暴射击天赋。"
	r.base_hp = 120.0
	r.shield_max = 30.0
	r.shield_regen = 2.0
	r.move_speed = 280.0
	r.dodge_rate = 0.05
	r.crit_rate = 0.03
	r.crit_mult = 1.2
	r.base_weapon_scene = "res://scenes/CannonBullet.tscn"
	r.talents = [
		{"name": "炮术专精", "desc": "加农炮基础等级 +1", "type": "cannon_base_level", "value": 1},
		{"name": "狂暴射击", "desc": "加农炮射速 +15%", "type": "cannon_fire_rate", "value": 1},
	]
	return r

static func _plant_data() -> RaceData:
	var r = RaceData.new()
	r.race_id = RaceID.PLANT
	r.display_name = "植物"
	r.description = "光子生物，使用磁轨炮武器，拥有高暴击率天赋。磁轨武器升级三项默认 +1，磁轨炮暴击率 +20%。"
	r.base_hp = 80.0
	r.shield_max = 60.0
	r.shield_regen = 5.0
	r.move_speed = 300.0
	r.dodge_rate = 0.08
	r.crit_rate = 0.10
	r.crit_mult = 1.8
	r.base_weapon_scene = "res://scenes/RailgunBullet.tscn"
	r.talents = [
		{"name": "磁轨专精", "desc": "磁轨炮基础等级 +1", "type": "railgun_base_level", "value": 1},
		{"name": "光子爆发", "desc": "磁轨炮暴击率 +20%", "type": "railgun_crit", "value": 1},
	]
	return r

static func _silicon_data() -> RaceData:
	var r = RaceData.new()
	r.race_id = RaceID.SILICON
	r.display_name = "硅基"
	r.description = "能量生命体，使用激光炮武器，拥有持续伤害天赋。激光武器升级三项默认 +1，激光宽度 +15%，持续时间 +15%。"
	r.base_hp = 90.0
	r.shield_max = 70.0
	r.shield_regen = 3.5
	r.move_speed = 310.0
	r.dodge_rate = 0.06
	r.crit_rate = 0.08
	r.crit_mult = 1.6
	r.base_weapon_scene = "res://scenes/LaserBeam.tscn"
	r.talents = [
		{"name": "激光专精", "desc": "激光炮基础等级 +1", "type": "laser_base_level", "value": 1},
		{"name": "能量聚焦", "desc": "激光宽度 +15%，持续时间 +15%", "type": "laser_width_duration", "value": 1},
	]
	return r
