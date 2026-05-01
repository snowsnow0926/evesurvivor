class_name ShipIconGenerator
extends RefCounted

const ICON_VIEWBOX: float = 100.0
const STYLE_DEFAULT = {
	"color": Color.WHITE,
	"line_width": 6.0,
}

enum ShipIcon {
	CAPSULE,
	FRIGATE,
	DESTROYER,
	CRUISER,
	BATTLECRUISER,
	BATTLESHIP,
	DRONE,
	INDUSTRIAL,
	SHUTTLE,
	FREIGHTER,
	DREADNOUGHT,
	CARRIER,
	FIGHTER,
	SUPERCAPITAL,
}

static var _data: Dictionary = {
	ShipIcon.CAPSULE: {
		name_zh = "太空舱",
		name_en = "Capsule",
		path = [
			["M", 50, 14], ["L", 72, 36], ["L", 72, 70],
			["L", 62, 70], ["L", 50, 57], ["L", 38, 70],
			["L", 28, 70], ["L", 28, 36], ["Z"]
		],
	},
	ShipIcon.FRIGATE: {
		name_zh = "护卫舰",
		name_en = "Frigate",
		path = [
			["M", 50, 28], ["L", 76, 66], ["L", 24, 66], ["Z"]
		],
	},
	ShipIcon.DESTROYER: {
		name_zh = "驱逐舰",
		name_en = "Destroyer",
		path = [
			["M", 50, 26], ["L", 76, 62], ["L", 24, 62], ["Z"],
			["M", 25, 76], ["L", 75, 76]
		],
	},
	ShipIcon.CRUISER: {
		name_zh = "巡洋舰",
		name_en = "Cruiser",
		path = [
			["M", 50, 18], ["L", 74, 40], ["L", 74, 70],
			["L", 26, 70], ["L", 26, 40], ["Z"]
		],
	},
	ShipIcon.BATTLECRUISER: {
		name_zh = "战列巡洋舰",
		name_en = "Battlecruiser",
		path = [
			["M", 50, 18], ["L", 74, 40], ["L", 74, 66],
			["L", 26, 66], ["L", 26, 40], ["Z"],
			["M", 27, 80], ["L", 73, 80]
		],
	},
	ShipIcon.BATTLESHIP: {
		name_zh = "战列舰",
		name_en = "Battleship",
		path = [
			["M", 50, 14], ["L", 74, 38], ["L", 74, 74],
			["L", 64, 74], ["L", 50, 60], ["L", 36, 74],
			["L", 26, 74], ["L", 26, 38], ["Z"]
		],
	},
	ShipIcon.DRONE: {
		name_zh = "无人机",
		name_en = "Drone",
		path = [
			["M", 36, 32], ["L", 44, 40],
			["M", 64, 32], ["L", 56, 40],
			["M", 36, 68], ["L", 44, 60],
			["M", 64, 68], ["L", 56, 60]
		],
	},
	ShipIcon.INDUSTRIAL: {
		name_zh = "工业舰",
		name_en = "Industrial",
		path = [
			["M", 28, 50], ["L", 28, 38], ["L", 40, 26],
			["L", 60, 26], ["L", 72, 38], ["L", 72, 50], ["Z"],
			["M", 28, 64], ["L", 72, 64],
			["M", 32, 74], ["L", 68, 74]
		],
	},
	ShipIcon.SHUTTLE: {
		name_zh = "穿梭机",
		name_en = "Shuttle",
		path = [
			["M", 25, 58], ["L", 36, 58], ["L", 50, 42],
			["L", 64, 58], ["L", 75, 58]
		],
	},
	ShipIcon.FREIGHTER: {
		name_zh = "货舰",
		name_en = "Freighter",
		path = [
			["M", 28, 48], ["L", 28, 36], ["L", 40, 26],
			["L", 60, 26], ["L", 72, 36], ["L", 72, 48], ["Z"],
			["M", 36, 64], ["Q", 36, 56, 44, 56], ["L", 56, 56],
			["Q", 64, 56, 64, 64], ["Q", 64, 72, 56, 72],
			["L", 44, 72], ["Q", 36, 72, 36, 64], ["Z"]
		],
	},
	ShipIcon.DREADNOUGHT: {
		name_zh = "无畏舰",
		name_en = "Dreadnought",
		path = [
			["M", 50, 16], ["L", 74, 42], ["L", 74, 76],
			["L", 64, 76], ["L", 50, 62], ["L", 36, 76],
			["L", 26, 76], ["L", 26, 42], ["Z"]
		],
	},
	ShipIcon.CARRIER: {
		name_zh = "航空母舰",
		name_en = "Carrier",
		path = [
			["M", 50, 18], ["L", 74, 42], ["L", 74, 62],
			["L", 58, 62], ["L", 50, 74], ["L", 42, 62],
			["L", 26, 62], ["L", 26, 42], ["Z"]
		],
	},
	ShipIcon.FIGHTER: {
		name_zh = "舰载机",
		name_en = "Fighter",
		path = [
			["M", 50, 30], ["L", 58, 38], ["M", 50, 30], ["L", 42, 38],
			["M", 35, 58], ["L", 43, 66], ["M", 35, 58], ["L", 27, 66],
			["M", 65, 58], ["L", 73, 66], ["M", 65, 58], ["L", 57, 66]
		],
	},
	ShipIcon.SUPERCAPITAL: {
		name_zh = "超级旗舰",
		name_en = "Supercapital",
		path = [
			["M", 50, 18], ["L", 70, 38], ["L", 50, 58], ["L", 30, 38], ["Z"],
			["M", 30, 66], ["L", 50, 82], ["L", 70, 66],
			["M", 35, 76], ["L", 50, 90], ["L", 65, 76]
		],
	},
}

static func get_icon_data(icon: ShipIcon) -> Dictionary:
	return _data.get(icon, _data[ShipIcon.CAPSULE])

static func get_name_zh(icon: ShipIcon) -> String:
	return _data[icon].name_zh

static func get_name_en(icon: ShipIcon) -> String:
	return _data[icon].name_en

static func get_all_icons() -> Array[ShipIcon]:
	return [
		ShipIcon.CAPSULE,
		ShipIcon.FRIGATE,
		ShipIcon.DESTROYER,
		ShipIcon.CRUISER,
		ShipIcon.BATTLECRUISER,
		ShipIcon.BATTLESHIP,
		ShipIcon.DRONE,
		ShipIcon.INDUSTRIAL,
		ShipIcon.SHUTTLE,
		ShipIcon.FREIGHTER,
		ShipIcon.DREADNOUGHT,
		ShipIcon.CARRIER,
		ShipIcon.FIGHTER,
		ShipIcon.SUPERCAPITAL,
	]

static func get_icon_for_ship_id(ship_id: int) -> ShipIcon:
	var all := get_all_icons()
	if ship_id < 0 or ship_id >= all.size():
		return ShipIcon.FRIGATE
	return all[ship_id]

static func get_icon_for_enemy_type(enemy_type: String) -> ShipIcon:
	match enemy_type:
		"capsule":   return ShipIcon.CAPSULE
		"frigate":   return ShipIcon.FRIGATE
		"destroyer": return ShipIcon.DESTROYER
		"cruiser":   return ShipIcon.CRUISER
		"battlecruiser": return ShipIcon.BATTLECRUISER
		"battleship":    return ShipIcon.BATTLESHIP
		"drone":         return ShipIcon.DRONE
		"industrial", "hauler": return ShipIcon.INDUSTRIAL
		"shuttle":   return ShipIcon.SHUTTLE
		"freighter": return ShipIcon.FREIGHTER
		"dreadnought": return ShipIcon.DREADNOUGHT
		"carrier":   return ShipIcon.CARRIER
		"fighter":   return ShipIcon.FIGHTER
		"supercapital": return ShipIcon.SUPERCAPITAL
		_: return ShipIcon.FRIGATE
