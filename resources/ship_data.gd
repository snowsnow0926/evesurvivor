class_name ShipData
extends Resource

enum ShipID { FRIGATE, CRUISER, BATTLECRUISER, BATTLESHIP, DREADNOUGHT, TITAN }

@export var ship_id: ShipID
@export var display_name: String
@export var repair_cost: int
@export var unlock_cost: int
@export var unlock_mineral_tier: int
@export var unlock_mineral_count: int
@export var is_unlocked: bool
@export var weapon_slot_count: int
@export var armor_slot_count: int
@export var upgraded_weapon_slots: int
@export var upgraded_armor_slots: int
@export var upgrade_star_coin: int
@export var upgrade_mineral_tier: int
@export var upgrade_mineral_count: int
@export var tonnage_tier: int
@export var base_hp: int
@export var base_shield: float
@export var base_shield_regen: float

static var _cache: Dictionary = {}

static func _ensure_cache() -> void:
	if _cache.is_empty():
		_cache[ShipID.FRIGATE] = _frigate()
		_cache[ShipID.CRUISER] = _cruiser()
		_cache[ShipID.BATTLECRUISER] = _battlecruiser()
		_cache[ShipID.BATTLESHIP] = _battleship()
		_cache[ShipID.DREADNOUGHT] = _dreadnought()
		_cache[ShipID.TITAN] = _titan()

static func get_all_ships() -> Array[ShipData]:
	_ensure_cache()
	return [
		_cache[ShipID.FRIGATE], _cache[ShipID.CRUISER],
		_cache[ShipID.BATTLECRUISER], _cache[ShipID.BATTLESHIP],
		_cache[ShipID.DREADNOUGHT], _cache[ShipID.TITAN]
	]

static func get_ship(ship_id: ShipID) -> ShipData:
	_ensure_cache()
	return _cache.get(ship_id, _cache[ShipID.FRIGATE])

static func _frigate() -> ShipData:
	var s = ShipData.new()
	s.ship_id = ShipID.FRIGATE
	s.display_name = "护卫舰"
	s.repair_cost = 500
	s.unlock_cost = 0
	s.is_unlocked = true
	s.weapon_slot_count = 1
	s.armor_slot_count = 1
	s.upgraded_weapon_slots = 2
	s.upgraded_armor_slots = 1
	s.upgrade_star_coin = 800
	s.upgrade_mineral_tier = 0
	s.upgrade_mineral_count = 10
	s.tonnage_tier = EquipmentData.TonnageTier.SMALL
	s.base_hp = 100
	s.base_shield = 50.0
	s.base_shield_regen = 4.0
	return s

static func _cruiser() -> ShipData:
	var s = ShipData.new()
	s.ship_id = ShipID.CRUISER
	s.display_name = "巡洋舰"
	s.repair_cost = 2000
	s.unlock_cost = 15000
	s.unlock_mineral_tier = 0
	s.unlock_mineral_count = 800
	s.is_unlocked = false
	s.weapon_slot_count = 2
	s.armor_slot_count = 1
	s.upgraded_weapon_slots = 2
	s.upgraded_armor_slots = 2
	s.upgrade_star_coin = 3000
	s.upgrade_mineral_tier = 0
	s.upgrade_mineral_count = 20
	s.tonnage_tier = EquipmentData.TonnageTier.MEDIUM
	s.base_hp = 250
	s.base_shield = 100.0
	s.base_shield_regen = 6.0
	return s

static func _battlecruiser() -> ShipData:
	var s = ShipData.new()
	s.ship_id = ShipID.BATTLECRUISER
	s.display_name = "战列巡洋舰"
	s.repair_cost = 5000
	s.unlock_cost = 50000
	s.unlock_mineral_tier = 0
	s.unlock_mineral_count = 4000
	s.is_unlocked = false
	s.weapon_slot_count = 2
	s.armor_slot_count = 2
	s.upgraded_weapon_slots = 3
	s.upgraded_armor_slots = 2
	s.upgrade_star_coin = 8000
	s.upgrade_mineral_tier = 1
	s.upgrade_mineral_count = 15
	s.tonnage_tier = EquipmentData.TonnageTier.MEDIUM
	s.base_hp = 450
	s.base_shield = 200.0
	s.base_shield_regen = 8.0
	return s

static func _battleship() -> ShipData:
	var s = ShipData.new()
	s.ship_id = ShipID.BATTLESHIP
	s.display_name = "战列舰"
	s.repair_cost = 15000
	s.unlock_cost = 150000
	s.unlock_mineral_tier = 1
	s.unlock_mineral_count = 18000
	s.is_unlocked = false
	s.weapon_slot_count = 3
	s.armor_slot_count = 3
	s.upgraded_weapon_slots = 3
	s.upgraded_armor_slots = 3
	s.upgrade_star_coin = 20000
	s.upgrade_mineral_tier = 1
	s.upgrade_mineral_count = 30
	s.tonnage_tier = EquipmentData.TonnageTier.LARGE
	s.base_hp = 800
	s.base_shield = 350.0
	s.base_shield_regen = 12.0
	return s

static func _dreadnought() -> ShipData:
	var s = ShipData.new()
	s.ship_id = ShipID.DREADNOUGHT
	s.display_name = "无畏舰"
	s.repair_cost = 50000
	s.unlock_cost = 450000
	s.unlock_mineral_tier = 2
	s.unlock_mineral_count = 50000
	s.is_unlocked = false
	s.weapon_slot_count = 4
	s.armor_slot_count = 4
	s.upgraded_weapon_slots = 4
	s.upgraded_armor_slots = 4
	s.upgrade_star_coin = 60000
	s.upgrade_mineral_tier = 2
	s.upgrade_mineral_count = 20
	s.tonnage_tier = EquipmentData.TonnageTier.FLAGSHIP
	s.base_hp = 1500
	s.base_shield = 600.0
	s.base_shield_regen = 18.0
	return s

static func _titan() -> ShipData:
	var s = ShipData.new()
	s.ship_id = ShipID.TITAN
	s.display_name = "泰坦"
	s.repair_cost = 200000
	s.unlock_cost = 1000000
	s.unlock_mineral_tier = 2
	s.unlock_mineral_count = 100000
	s.is_unlocked = false
	s.weapon_slot_count = 6
	s.armor_slot_count = 5
	s.upgraded_weapon_slots = 6
	s.upgraded_armor_slots = 6
	s.upgrade_star_coin = 250000
	s.upgrade_mineral_tier = 2
	s.upgrade_mineral_count = 50
	s.tonnage_tier = EquipmentData.TonnageTier.FLAGSHIP
	s.base_hp = 3000
	s.base_shield = 1200.0
	s.base_shield_regen = 30.0
	return s
