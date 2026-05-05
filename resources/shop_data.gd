class_name ShopItemData
extends Resource

enum ShopItemID {
	SMALL_MISSILE, MEDIUM_MISSILE, LARGE_MISSILE, FLAGSHIP_MISSILE,
	SMALL_CANNON, MEDIUM_CANNON, LARGE_CANNON, FLAGSHIP_CANNON,
	SMALL_RAILGUN, MEDIUM_RAILGUN, LARGE_RAILGUN, FLAGSHIP_RAILGUN,
	SMALL_LASER, MEDIUM_LASER, LARGE_LASER, FLAGSHIP_LASER,
	SMALL_SHIELD_OPTIMIZER, MEDIUM_SHIELD_OPTIMIZER, LARGE_SHIELD_OPTIMIZER, FLAGSHIP_SHIELD_OPTIMIZER,
	SMALL_SHIELD_REGEN, MEDIUM_SHIELD_REGEN, LARGE_SHIELD_REGEN, FLAGSHIP_SHIELD_REGEN,
}
enum MineralTier { LOW, MID, HIGH }
enum EquipType { WEAPON, ARMOR }
enum TonnageTier { SMALL, MEDIUM, LARGE, FLAGSHIP }

@export var shop_item_id: ShopItemID
@export var display_name: String
@export var description: String
@export var star_coin_price: int
@export var mineral_tier: MineralTier
@export var mineral_count: int
@export var sell_price: int
@export var base_damage: float
@export var fire_interval: float
@export var range: float
@export var crit_rate: float
@export var crit_mult: float
@export var scene_path: String
@export var equip_type: EquipType
@export var shield_bonus: float
@export var shield_regen_bonus: float
@export var quality: int
@export var tonnage_tier: TonnageTier

static var _all_items_cache: Array[ShopItemData] = []
static var _by_id_cache: Dictionary = {}

static func _ensure_cache() -> void:
	if _all_items_cache.is_empty():
		_all_items_cache = [
			_small_missile(), _medium_missile(), _large_missile(), _flagship_missile(),
			_small_cannon(), _medium_cannon(), _large_cannon(), _flagship_cannon(),
			_small_railgun(), _medium_railgun(), _large_railgun(), _flagship_railgun(),
			_small_laser(), _medium_laser(), _large_laser(), _flagship_laser(),
			_small_shield_optimizer(), _medium_shield_optimizer(), _large_shield_optimizer(), _flagship_shield_optimizer(),
			_small_shield_regen(), _medium_shield_regen(), _large_shield_regen(), _flagship_shield_regen(),
		]
		for item in _all_items_cache:
			_by_id_cache[item.shop_item_id] = item

static func get_all_shop_items() -> Array[ShopItemData]:
	_ensure_cache()
	return _all_items_cache

static func get_item(item_id: ShopItemID) -> ShopItemData:
	_ensure_cache()
	return _by_id_cache.get(item_id, _small_missile())

static func _small_missile() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.SMALL_MISSILE
	w.equip_type = EquipType.WEAPON
	w.tonnage_tier = TonnageTier.SMALL
	w.display_name = "小型导弹发射器"
	w.description = "发射追踪导弹，每枚造成 15 伤害"
	w.star_coin_price = 800
	w.mineral_tier = MineralTier.LOW
	w.mineral_count = 0
	w.sell_price = 320
	w.base_damage = 15.0
	w.fire_interval = 0.8
	w.range = 600.0
	w.crit_rate = 0.05
	w.crit_mult = 1.5
	w.scene_path = "res://scenes/Missile.tscn"
	w.shield_bonus = 0.0
	w.shield_regen_bonus = 0.0
	w.quality = 0
	return w

static func _medium_missile() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.MEDIUM_MISSILE
	w.equip_type = EquipType.WEAPON
	w.tonnage_tier = TonnageTier.MEDIUM
	w.display_name = "中型导弹发射器"
	w.description = "强化追踪导弹，每枚造成 25 伤害"
	w.star_coin_price = 3000
	w.mineral_tier = MineralTier.LOW
	w.mineral_count = 0
	w.sell_price = 1200
	w.base_damage = 25.0
	w.fire_interval = 1.0
	w.range = 700.0
	w.crit_rate = 0.06
	w.crit_mult = 1.5
	w.scene_path = "res://scenes/Missile.tscn"
	w.shield_bonus = 0.0
	w.shield_regen_bonus = 0.0
	w.quality = 0
	return w

static func _large_missile() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.LARGE_MISSILE
	w.equip_type = EquipType.WEAPON
	w.tonnage_tier = TonnageTier.LARGE
	w.display_name = "大型导弹发射器"
	w.description = "重型追踪导弹，每枚造成 40 伤害"
	w.star_coin_price = 12000
	w.mineral_tier = MineralTier.MID
	w.mineral_count = 0
	w.sell_price = 4800
	w.base_damage = 40.0
	w.fire_interval = 1.3
	w.range = 800.0
	w.crit_rate = 0.07
	w.crit_mult = 1.6
	w.scene_path = "res://scenes/Missile.tscn"
	w.shield_bonus = 0.0
	w.shield_regen_bonus = 0.0
	w.quality = 0
	return w

static func _flagship_missile() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.FLAGSHIP_MISSILE
	w.equip_type = EquipType.WEAPON
	w.tonnage_tier = TonnageTier.FLAGSHIP
	w.display_name = "旗舰级导弹发射器"
	w.description = "终极追踪导弹，每枚造成 65 伤害"
	w.star_coin_price = 40000
	w.mineral_tier = MineralTier.HIGH
	w.mineral_count = 0
	w.sell_price = 16000
	w.base_damage = 65.0
	w.fire_interval = 1.6
	w.range = 1000.0
	w.crit_rate = 0.08
	w.crit_mult = 1.7
	w.scene_path = "res://scenes/Missile.tscn"
	w.shield_bonus = 0.0
	w.shield_regen_bonus = 0.0
	w.quality = 0
	return w

static func _small_cannon() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.SMALL_CANNON
	w.equip_type = EquipType.WEAPON
	w.tonnage_tier = TonnageTier.SMALL
	w.display_name = "小型加农炮"
	w.description = "高爆加农炮，每发造成 25 伤害"
	w.star_coin_price = 1200
	w.mineral_tier = MineralTier.LOW
	w.mineral_count = 0
	w.sell_price = 480
	w.base_damage = 25.0
	w.fire_interval = 1.2
	w.range = 400.0
	w.crit_rate = 0.03
	w.crit_mult = 1.2
	w.scene_path = "res://scenes/CannonBullet.tscn"
	w.shield_bonus = 0.0
	w.shield_regen_bonus = 0.0
	w.quality = 0
	return w

static func _medium_cannon() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.MEDIUM_CANNON
	w.equip_type = EquipType.WEAPON
	w.tonnage_tier = TonnageTier.MEDIUM
	w.display_name = "中型加农炮"
	w.description = "强化高爆加农炮，每发造成 40 伤害"
	w.star_coin_price = 5000
	w.mineral_tier = MineralTier.LOW
	w.mineral_count = 0
	w.sell_price = 2000
	w.base_damage = 40.0
	w.fire_interval = 1.5
	w.range = 500.0
	w.crit_rate = 0.04
	w.crit_mult = 1.3
	w.scene_path = "res://scenes/CannonBullet.tscn"
	w.shield_bonus = 0.0
	w.shield_regen_bonus = 0.0
	w.quality = 0
	return w

static func _large_cannon() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.LARGE_CANNON
	w.equip_type = EquipType.WEAPON
	w.tonnage_tier = TonnageTier.LARGE
	w.display_name = "大型加农炮"
	w.description = "重型高爆加农炮，每发造成 65 伤害"
	w.star_coin_price = 18000
	w.mineral_tier = MineralTier.MID
	w.mineral_count = 0
	w.sell_price = 7200
	w.base_damage = 65.0
	w.fire_interval = 2.0
	w.range = 600.0
	w.crit_rate = 0.05
	w.crit_mult = 1.4
	w.scene_path = "res://scenes/CannonBullet.tscn"
	w.shield_bonus = 0.0
	w.shield_regen_bonus = 0.0
	w.quality = 0
	return w

static func _flagship_cannon() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.FLAGSHIP_CANNON
	w.equip_type = EquipType.WEAPON
	w.tonnage_tier = TonnageTier.FLAGSHIP
	w.display_name = "旗舰级加农炮"
	w.description = "终极高爆加农炮，每发造成 100 伤害"
	w.star_coin_price = 60000
	w.mineral_tier = MineralTier.HIGH
	w.mineral_count = 0
	w.sell_price = 24000
	w.base_damage = 100.0
	w.fire_interval = 2.5
	w.range = 800.0
	w.crit_rate = 0.06
	w.crit_mult = 1.5
	w.scene_path = "res://scenes/CannonBullet.tscn"
	w.shield_bonus = 0.0
	w.shield_regen_bonus = 0.0
	w.quality = 0
	return w

static func _small_railgun() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.SMALL_RAILGUN
	w.equip_type = EquipType.WEAPON
	w.tonnage_tier = TonnageTier.SMALL
	w.display_name = "小型磁轨炮"
	w.description = "高速磁轨炮，每发造成 30 伤害"
	w.star_coin_price = 2000
	w.mineral_tier = MineralTier.MID
	w.mineral_count = 0
	w.sell_price = 800
	w.base_damage = 30.0
	w.fire_interval = 0.6
	w.range = 400.0
	w.crit_rate = 0.35
	w.crit_mult = 1.5
	w.scene_path = "res://scenes/RailgunBullet.tscn"
	w.shield_bonus = 0.0
	w.shield_regen_bonus = 0.0
	w.quality = 0
	return w

static func _medium_railgun() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.MEDIUM_RAILGUN
	w.equip_type = EquipType.WEAPON
	w.tonnage_tier = TonnageTier.MEDIUM
	w.display_name = "中型磁轨炮"
	w.description = "强化高速磁轨炮，每发造成 50 伤害"
	w.star_coin_price = 8000
	w.mineral_tier = MineralTier.MID
	w.mineral_count = 0
	w.sell_price = 3200
	w.base_damage = 50.0
	w.fire_interval = 0.8
	w.range = 500.0
	w.crit_rate = 0.38
	w.crit_mult = 1.6
	w.scene_path = "res://scenes/RailgunBullet.tscn"
	w.shield_bonus = 0.0
	w.shield_regen_bonus = 0.0
	w.quality = 0
	return w

static func _large_railgun() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.LARGE_RAILGUN
	w.equip_type = EquipType.WEAPON
	w.tonnage_tier = TonnageTier.LARGE
	w.display_name = "大型磁轨炮"
	w.description = "重型磁轨炮，每发造成 80 伤害"
	w.star_coin_price = 25000
	w.mineral_tier = MineralTier.MID
	w.mineral_count = 0
	w.sell_price = 10000
	w.base_damage = 80.0
	w.fire_interval = 1.0
	w.range = 600.0
	w.crit_rate = 0.40
	w.crit_mult = 1.7
	w.scene_path = "res://scenes/RailgunBullet.tscn"
	w.shield_bonus = 0.0
	w.shield_regen_bonus = 0.0
	w.quality = 0
	return w

static func _flagship_railgun() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.FLAGSHIP_RAILGUN
	w.equip_type = EquipType.WEAPON
	w.tonnage_tier = TonnageTier.FLAGSHIP
	w.display_name = "旗舰级磁轨炮"
	w.description = "终极磁轨炮，每发造成 120 伤害"
	w.star_coin_price = 80000
	w.mineral_tier = MineralTier.HIGH
	w.mineral_count = 0
	w.sell_price = 32000
	w.base_damage = 120.0
	w.fire_interval = 1.2
	w.range = 800.0
	w.crit_rate = 0.45
	w.crit_mult = 1.8
	w.scene_path = "res://scenes/RailgunBullet.tscn"
	w.shield_bonus = 0.0
	w.shield_regen_bonus = 0.0
	w.quality = 0
	return w

static func _small_laser() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.SMALL_LASER
	w.equip_type = EquipType.WEAPON
	w.tonnage_tier = TonnageTier.SMALL
	w.display_name = "小型激光炮"
	w.description = "持续激光束，射程700像素，对路径上所有目标造成伤害"
	w.star_coin_price = 2500
	w.mineral_tier = MineralTier.MID
	w.mineral_count = 0
	w.sell_price = 1000
	w.base_damage = 12.0
	w.fire_interval = 2.5
	w.range = 700.0
	w.crit_rate = 0.08
	w.crit_mult = 1.6
	w.scene_path = "res://scenes/LaserBeam.tscn"
	w.shield_bonus = 0.0
	w.shield_regen_bonus = 0.0
	w.quality = 0
	return w

static func _medium_laser() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.MEDIUM_LASER
	w.equip_type = EquipType.WEAPON
	w.tonnage_tier = TonnageTier.MEDIUM
	w.display_name = "中型激光炮"
	w.description = "强化持续激光束，射程850像素，对路径上所有目标造成伤害"
	w.star_coin_price = 6000
	w.mineral_tier = MineralTier.MID
	w.mineral_count = 0
	w.sell_price = 2400
	w.base_damage = 18.0
	w.fire_interval = 3.0
	w.range = 850.0
	w.crit_rate = 0.1
	w.crit_mult = 1.7
	w.scene_path = "res://scenes/LaserBeam.tscn"
	w.shield_bonus = 0.0
	w.shield_regen_bonus = 0.0
	w.quality = 0
	return w

static func _large_laser() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.LARGE_LASER
	w.equip_type = EquipType.WEAPON
	w.tonnage_tier = TonnageTier.LARGE
	w.display_name = "大型激光炮"
	w.description = "重型持续激光束，射程1000像素，对路径上所有目标造成伤害"
	w.star_coin_price = 20000
	w.mineral_tier = MineralTier.HIGH
	w.mineral_count = 0
	w.sell_price = 8000
	w.base_damage = 30.0
	w.fire_interval = 3.5
	w.range = 1000.0
	w.crit_rate = 0.12
	w.crit_mult = 1.8
	w.scene_path = "res://scenes/LaserBeam.tscn"
	w.shield_bonus = 0.0
	w.shield_regen_bonus = 0.0
	w.quality = 0
	return w

static func _flagship_laser() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.FLAGSHIP_LASER
	w.equip_type = EquipType.WEAPON
	w.tonnage_tier = TonnageTier.FLAGSHIP
	w.display_name = "旗舰级激光炮"
	w.description = "终极持续激光束，射程1200像素，对路径上所有目标造成伤害"
	w.star_coin_price = 70000
	w.mineral_tier = MineralTier.HIGH
	w.mineral_count = 0
	w.sell_price = 28000
	w.base_damage = 45.0
	w.fire_interval = 4.0
	w.range = 1200.0
	w.crit_rate = 0.15
	w.crit_mult = 2.0
	w.scene_path = "res://scenes/LaserBeam.tscn"
	w.shield_bonus = 0.0
	w.shield_regen_bonus = 0.0
	w.quality = 0
	return w

static func _small_shield_optimizer() -> ShopItemData:
	var e = ShopItemData.new()
	e.shop_item_id = ShopItemID.SMALL_SHIELD_OPTIMIZER
	e.equip_type = EquipType.ARMOR
	e.tonnage_tier = TonnageTier.SMALL
	e.display_name = "小型立场优化器"
	e.description = "护盾上限 +30"
	e.star_coin_price = 600
	e.mineral_tier = MineralTier.LOW
	e.mineral_count = 0
	e.sell_price = 240
	e.base_damage = 0.0
	e.fire_interval = 0.0
	e.range = 0.0
	e.crit_rate = 0.0
	e.crit_mult = 1.0
	e.scene_path = ""
	e.shield_bonus = 30.0
	e.shield_regen_bonus = 0.0
	e.quality = 0
	return e

static func _medium_shield_optimizer() -> ShopItemData:
	var e = ShopItemData.new()
	e.shop_item_id = ShopItemID.MEDIUM_SHIELD_OPTIMIZER
	e.equip_type = EquipType.ARMOR
	e.tonnage_tier = TonnageTier.MEDIUM
	e.display_name = "中型立场优化器"
	e.description = "护盾上限 +60"
	e.star_coin_price = 3000
	e.mineral_tier = MineralTier.LOW
	e.mineral_count = 0
	e.sell_price = 1200
	e.base_damage = 0.0
	e.fire_interval = 0.0
	e.range = 0.0
	e.crit_rate = 0.0
	e.crit_mult = 1.0
	e.scene_path = ""
	e.shield_bonus = 60.0
	e.shield_regen_bonus = 0.0
	e.quality = 0
	return e

static func _large_shield_optimizer() -> ShopItemData:
	var e = ShopItemData.new()
	e.shop_item_id = ShopItemID.LARGE_SHIELD_OPTIMIZER
	e.equip_type = EquipType.ARMOR
	e.tonnage_tier = TonnageTier.LARGE
	e.display_name = "大型立场优化器"
	e.description = "护盾上限 +100"
	e.star_coin_price = 10000
	e.mineral_tier = MineralTier.MID
	e.mineral_count = 0
	e.sell_price = 4000
	e.base_damage = 0.0
	e.fire_interval = 0.0
	e.range = 0.0
	e.crit_rate = 0.0
	e.crit_mult = 1.0
	e.scene_path = ""
	e.shield_bonus = 100.0
	e.shield_regen_bonus = 0.0
	e.quality = 0
	return e

static func _flagship_shield_optimizer() -> ShopItemData:
	var e = ShopItemData.new()
	e.shop_item_id = ShopItemID.FLAGSHIP_SHIELD_OPTIMIZER
	e.equip_type = EquipType.ARMOR
	e.tonnage_tier = TonnageTier.FLAGSHIP
	e.display_name = "旗舰级立场优化器"
	e.description = "护盾上限 +160"
	e.star_coin_price = 35000
	e.mineral_tier = MineralTier.HIGH
	e.mineral_count = 0
	e.sell_price = 14000
	e.base_damage = 0.0
	e.fire_interval = 0.0
	e.range = 0.0
	e.crit_rate = 0.0
	e.crit_mult = 1.0
	e.scene_path = ""
	e.shield_bonus = 160.0
	e.shield_regen_bonus = 0.0
	e.quality = 0
	return e

static func _small_shield_regen() -> ShopItemData:
	var e = ShopItemData.new()
	e.shop_item_id = ShopItemID.SMALL_SHIELD_REGEN
	e.equip_type = EquipType.ARMOR
	e.tonnage_tier = TonnageTier.SMALL
	e.display_name = "小型护盾回充器"
	e.description = "护盾回充 +2/秒"
	e.star_coin_price = 1000
	e.mineral_tier = MineralTier.LOW
	e.mineral_count = 0
	e.sell_price = 400
	e.base_damage = 0.0
	e.fire_interval = 0.0
	e.range = 0.0
	e.crit_rate = 0.0
	e.crit_mult = 1.0
	e.scene_path = ""
	e.shield_bonus = 0.0
	e.shield_regen_bonus = 2.0
	e.quality = 0
	return e

static func _medium_shield_regen() -> ShopItemData:
	var e = ShopItemData.new()
	e.shop_item_id = ShopItemID.MEDIUM_SHIELD_REGEN
	e.equip_type = EquipType.ARMOR
	e.tonnage_tier = TonnageTier.MEDIUM
	e.display_name = "中型护盾回充器"
	e.description = "护盾回充 +4/秒"
	e.star_coin_price = 4500
	e.mineral_tier = MineralTier.LOW
	e.mineral_count = 0
	e.sell_price = 1800
	e.base_damage = 0.0
	e.fire_interval = 0.0
	e.range = 0.0
	e.crit_rate = 0.0
	e.crit_mult = 1.0
	e.scene_path = ""
	e.shield_bonus = 0.0
	e.shield_regen_bonus = 4.0
	e.quality = 0
	return e

static func _large_shield_regen() -> ShopItemData:
	var e = ShopItemData.new()
	e.shop_item_id = ShopItemID.LARGE_SHIELD_REGEN
	e.equip_type = EquipType.ARMOR
	e.tonnage_tier = TonnageTier.LARGE
	e.display_name = "大型护盾回充器"
	e.description = "护盾回充 +7/秒"
	e.star_coin_price = 15000
	e.mineral_tier = MineralTier.MID
	e.mineral_count = 0
	e.sell_price = 6000
	e.base_damage = 0.0
	e.fire_interval = 0.0
	e.range = 0.0
	e.crit_rate = 0.0
	e.crit_mult = 1.0
	e.scene_path = ""
	e.shield_bonus = 0.0
	e.shield_regen_bonus = 7.0
	e.quality = 0
	return e

static func _flagship_shield_regen() -> ShopItemData:
	var e = ShopItemData.new()
	e.shop_item_id = ShopItemID.FLAGSHIP_SHIELD_REGEN
	e.equip_type = EquipType.ARMOR
	e.tonnage_tier = TonnageTier.FLAGSHIP
	e.display_name = "旗舰级护盾回充器"
	e.description = "护盾回充 +12/秒"
	e.star_coin_price = 55000
	e.mineral_tier = MineralTier.HIGH
	e.mineral_count = 0
	e.sell_price = 22000
	e.base_damage = 0.0
	e.fire_interval = 0.0
	e.range = 0.0
	e.crit_rate = 0.0
	e.crit_mult = 1.0
	e.scene_path = ""
	e.shield_bonus = 0.0
	e.shield_regen_bonus = 12.0
	e.quality = 0
	return e

func to_inventory_dict() -> Dictionary:
	return {
		"equip_id": str(ShopItemID.keys()[shop_item_id]) + "_" + str(Time.get_ticks_msec()),
		"equip_type": ShopItemData.EquipType.keys()[equip_type],
		"shop_item_id": shop_item_id,
		"quality": quality,
		"name": display_name,
		"description": description,
		"scene_path": scene_path,
		"base_damage": base_damage,
		"fire_interval": fire_interval,
		"range": range,
		"crit_rate": crit_rate,
		"crit_mult": crit_mult,
		"shield_bonus": shield_bonus,
		"shield_regen_bonus": shield_regen_bonus,
		"tonnage_tier": tonnage_tier,
		"star_coin_price": star_coin_price,
	}
