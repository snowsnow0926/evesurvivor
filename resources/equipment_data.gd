class_name EquipmentData
extends Resource

enum EquipType { WEAPON, ARMOR }
enum Quality { COMMON, UNCOMMON, RARE, LEGENDARY, EPIC, MYTHIC }
enum TonnageTier { SMALL, MEDIUM, LARGE, FLAGSHIP }

static func get_quality_name(q: Quality) -> String:
	match q:
		Quality.COMMON: return "普通"
		Quality.UNCOMMON: return "精良"
		Quality.RARE: return "稀有"
		Quality.LEGENDARY: return "传奇"
		Quality.EPIC: return "传说"
		Quality.MYTHIC: return "神话"
	return "?"

static func get_quality_color(q: Quality) -> Color:
	match q:
		Quality.COMMON: return Color(1.0, 1.0, 1.0)
		Quality.UNCOMMON: return Color(0.118, 1.0, 0.369)
		Quality.RARE: return Color(0.302, 0.651, 1.0)
		Quality.LEGENDARY: return Color(0.784, 0.302, 1.0)
		Quality.EPIC: return Color(1.0, 0.549, 0.0)
		Quality.MYTHIC: return Color(1.0, 0.2, 0.2)
	return Color.WHITE

static func get_quality_mult(q: Quality) -> float:
	match q:
		Quality.COMMON: return 1.0
		Quality.UNCOMMON: return 1.3
		Quality.RARE: return 1.6
		Quality.LEGENDARY: return 2.0
		Quality.EPIC: return 2.8
		Quality.MYTHIC: return 4.0
	return 1.0

static func get_tonnage_name(t: int) -> String:
	match t:
		0: return "小型"
		1: return "中型"
		2: return "大型"
		3: return "旗舰级"
	return "?"

static func get_tonnage_color(t: int) -> Color:
	match t:
		0: return Color(0.7, 0.7, 0.7)
		1: return Color(0.118, 1.0, 0.369)
		2: return Color(0.302, 0.651, 1.0)
		3: return Color(1.0, 0.549, 0.0)
	return Color.WHITE

static func can_equip_on_ship(ship_tonnage: int, equip_tonnage: int) -> bool:
	match ship_tonnage:
		0: return equip_tonnage == TonnageTier.SMALL
		1: return equip_tonnage <= TonnageTier.MEDIUM
		2: return equip_tonnage <= TonnageTier.LARGE
		3: return true
	return false
