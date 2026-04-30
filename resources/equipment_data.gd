class_name EquipmentData
extends Resource

enum EquipType { WEAPON, ARMOR }
enum Quality { COMMON, UNCOMMON, RARE, LEGENDARY, EPIC, MYTHIC }

@export var equip_id: String
@export var equip_type: EquipType
@export var quality: Quality
@export var display_name: String
@export var description: String
@export var base_damage: float
@export var base_armor: float
@export var icon: String

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
		Quality.UNCOMMON: return 1.2
		Quality.RARE: return 1.5
		Quality.LEGENDARY: return 2.0
		Quality.EPIC: return 2.8
		Quality.MYTHIC: return 4.0
	return 1.0

static func create_random_equipment(equip_type: EquipType, quality: Quality) -> EquipmentData:
	var e = EquipmentData.new()
	e.equip_type = equip_type
	e.quality = quality
	e.equip_id = str(equip_type) + "_" + str(quality) + "_" + str(randi())
	e.base_damage = 0.0
	e.base_armor = 0.0
	e.display_name = get_quality_name(quality)
	if equip_type == EquipType.WEAPON:
		e.display_name += " 武器"
		e.base_damage = 10.0 * get_quality_mult(quality)
	else:
		e.display_name += " 护甲"
		e.base_armor = 5.0 * get_quality_mult(quality)
	return e
