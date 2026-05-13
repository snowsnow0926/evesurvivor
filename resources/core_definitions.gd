class_name CoreDefinitions
extends RefCounted

## 每个词条的详细定义，供UI显示和效果应用使用

const SKILL_DEFINITIONS: Dictionary = {
	# ==================== 通用词条 ====================
	"damage": {
		"name": "伤害强化",
		"name_en": "Damage Boost",
		"desc_templates": [
			"所有武器伤害 x1.2",
			"所有武器伤害 x1.44",
			"所有武器伤害 x1.728",
			"所有武器伤害 x2.07",
			"所有武器伤害 x2.49",
			"所有武器伤害 x2.99",
			"所有武器伤害 x3.58",
			"所有武器伤害 x4.3",
		],
		"color": Color(1.0, 0.4, 0.4),
	},
	"shield_max": {
		"name": "临时护盾",
		"name_en": "Shield Boost",
		"desc_templates": [
			"护盾上限 +30，立即补满",
			"护盾上限 +60，立即补满",
			"护盾上限 +90，立即补满",
			"护盾上限 +120，立即补满",
			"护盾上限 +150，立即补满",
			"护盾上限 +180，立即补满",
			"护盾上限 +210，立即补满",
			"护盾上限 +240，立即补满",
		],
		"color": Color(0.4, 0.7, 1.0),
	},
	"shield_regen": {
		"name": "护盾充能",
		"name_en": "Shield Regen",
		"desc_templates": [
			"护盾回复速度 x1.5",
			"护盾回复速度 x2.25",
			"护盾回复速度 x3.38",
			"护盾回复速度 x5.06",
			"护盾回复速度 x7.59",
			"护盾回复速度 x11.39",
			"护盾回复速度 x17.09",
			"护盾回复速度 x25.63",
		],
		"color": Color(0.3, 0.9, 0.5),
	},

	# ==================== 导弹词条 ====================
	"fire_coverage": {
		"name": "火力覆盖",
		"name_en": "Fire Coverage",
		"desc_templates": [
			"导弹单次射击2发",
			"导弹单次射击3发",
			"导弹单次射击4发",
			"导弹单次射击5发",
			"导弹单次射击6发",
			"导弹单次射击7发",
		],
		"color": Color(0.3, 0.8, 1.0),
	},
	"silent_hunter": {
		"name": "静默猎手",
		"name_en": "Silent Hunter",
		"desc_templates": [
			"静止时导弹射速 +15%",
			"静止时导弹射速 +30%",
			"静止时导弹射速 +45%",
			"静止时导弹射速 +60%",
			"静止时导弹射速 +75%",
			"静止时导弹射速 +90%",
		],
		"color": Color(0.6, 0.4, 1.0),
	},
	"precision_kill": {
		"name": "精准猎杀",
		"name_en": "Precision Kill",
		"desc_templates": [
			"导弹索敌范围 +100",
			"导弹索敌范围 +200",
			"导弹索敌范围 +300",
			"导弹索敌范围 +400",
			"导弹索敌范围 +500",
			"导弹索敌范围 +600",
		],
		"color": Color(0.2, 0.9, 0.6),
	},

	# ==================== 加农炮词条 ====================
	"cannon_bloodthirst": {
		"name": "嗜血残暴",
		"name_en": "Cannon Bloodthirst",
		"desc_templates": [
			"加农炮单次射击2发",
			"加农炮单次射击3发",
			"加农炮单次射击4发",
			"加农炮单次射击5发",
			"加农炮单次射击6发",
			"加农炮单次射击7发",
		],
		"color": Color(1.0, 0.3, 0.3),
	},
	"cannon_rush": {
		"name": "狂飙突进",
		"name_en": "Cannon Rush",
		"desc_templates": [
			"移动时加农炮射速 +15%",
			"移动时加农炮射速 +30%",
			"移动时加农炮射速 +45%",
			"移动时加农炮射速 +60%",
			"移动时加农炮射速 +75%",
			"移动时加农炮射速 +90%",
		],
		"color": Color(1.0, 0.6, 0.2),
	},
	"cannon_vengeance": {
		"name": "为了部落",
		"name_en": "Cannon Vengeance",
		"desc_templates": [
			"受伤时加农炮射速 +15%，持续2秒",
			"受伤时加农炮射速 +30%，持续2秒",
			"受伤时加农炮射速 +45%，持续2秒",
			"受伤时加农炮射速 +60%，持续2秒",
			"受伤时加农炮射速 +75%，持续2秒",
			"受伤时加农炮射速 +90%，持续2秒",
		],
		"color": Color(1.0, 0.2, 0.5),
	},

	# ==================== 磁轨炮词条 ====================
	"railgun_damage": {
		"name": "一发入魂",
		"name_en": "Railgun Damage",
		"desc_templates": [
			"磁轨炮伤害 x1.2",
			"磁轨炮伤害 x1.44",
			"磁轨炮伤害 x1.73",
			"磁轨炮伤害 x2.07",
			"磁轨炮伤害 x2.49",
			"磁轨炮伤害 x2.99",
		],
		"color": Color(0.6, 0.3, 1.0),
	},
	"railgun_crit": {
		"name": "命中注定",
		"name_en": "Railgun Crit",
		"desc_templates": [
			"磁轨炮暴击率 +10%",
			"磁轨炮暴击率 +20%",
			"磁轨炮暴击率 +30%",
			"磁轨炮暴击率 +40%",
			"磁轨炮暴击率 +50%",
			"磁轨炮暴击率 +60%",
		],
		"color": Color(0.8, 0.5, 1.0),
	},
	"railgun_multi": {
		"name": "多重射击",
		"name_en": "Railgun Multi",
		"desc_templates": [
			"磁轨炮单次射击2发",
			"磁轨炮单次射击3发",
			"磁轨炮单次射击4发",
			"磁轨炮单次射击5发",
			"磁轨炮单次射击6发",
			"磁轨炮单次射击7发",
		],
		"color": Color(0.5, 0.7, 1.0),
	},

	# ==================== 激光词条 ====================
	"laser_duration": {
		"name": "高能光束",
		"name_en": "Laser Duration",
		"desc_templates": [
			"激光持续时间 x1.2",
			"激光持续时间 x1.44",
			"激光持续时间 x1.73",
			"激光持续时间 x2.07",
			"激光持续时间 x2.49",
			"激光持续时间 x2.99",
		],
		"color": Color(0.3, 1.0, 0.8),
	},
	"laser_width": {
		"name": "高效射击",
		"name_en": "Laser Width",
		"desc_templates": [
			"激光宽度 +20%",
			"激光宽度 +40%",
			"激光宽度 +60%",
			"激光宽度 +80%",
			"激光宽度 +100%",
			"激光宽度 +120%",
		],
		"color": Color(1.0, 0.4, 0.8),
	},
	"laser_shield": {
		"name": "护盾中和",
		"name_en": "Laser Shield Pierce",
		"desc_templates": [
			"激光对护盾伤害 +20%",
			"激光对护盾伤害 +40%",
			"激光对护盾伤害 +60%",
			"激光对护盾伤害 +80%",
			"激光对护盾伤害 +100%",
			"激光对护盾伤害 +120%",
		],
		"color": Color(0.4, 0.8, 1.0),
	},
}


static func get_skill_desc(skill_id: String, level: int) -> String:
	var def = SKILL_DEFINITIONS.get(skill_id, {})
	var templates: Array = def.get("desc_templates", [])
	if templates.is_empty():
		return def.get("name", skill_id)
	# level是当前等级，取模板索引 (level - 1)，上限6级取索引5
	var idx = mini(level - 1, templates.size() - 1)
	if level <= 0:
		return templates[0] if not templates.is_empty() else def.get("name", skill_id)
	return templates[idx]


static func get_skill_color(skill_id: String) -> Color:
	var def = SKILL_DEFINITIONS.get(skill_id, {})
	return def.get("color", Color.WHITE)


static func get_skill_name(skill_id: String) -> String:
	var def = SKILL_DEFINITIONS.get(skill_id, {})
	return def.get("name", skill_id)
