class_name ShopItemData
extends Resource

enum ShopItemID { SMALL_MISSILE, SMALL_CANNON, SMALL_RAILGUN, SMALL_LASER, SMALL_SHIELD_OPTIMIZER, SMALL_SHIELD_REGEN }
enum MineralTier { LOW, MID, HIGH }
enum EquipType { WEAPON, ARMOR }

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

static func get_all_shop_items() -> Array[ShopItemData]:
	return [
		_small_missile(),
		_small_cannon(),
		_small_railgun(),
		_small_laser(),
		_small_shield_optimizer(),
		_small_shield_regen(),
	]

static func get_item(item_id: ShopItemID) -> ShopItemData:
	match item_id:
		ShopItemID.SMALL_MISSILE: return _small_missile()
		ShopItemID.SMALL_CANNON: return _small_cannon()
		ShopItemID.SMALL_RAILGUN: return _small_railgun()
		ShopItemID.SMALL_LASER: return _small_laser()
		ShopItemID.SMALL_SHIELD_OPTIMIZER: return _small_shield_optimizer()
		ShopItemID.SMALL_SHIELD_REGEN: return _small_shield_regen()
	return _small_missile()

static func _small_missile() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.SMALL_MISSILE
	w.equip_type = EquipType.WEAPON
	w.display_name = "小型导弹发射器"
	w.description = "发射追踪导弹，每枚造成 %d 伤害" % 15
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

static func _small_cannon() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.SMALL_CANNON
	w.equip_type = EquipType.WEAPON
	w.display_name = "小型加农炮"
	w.description = "高爆加农炮，每发造成 %d 伤害" % 25
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

static func _small_railgun() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.SMALL_RAILGUN
	w.equip_type = EquipType.WEAPON
	w.display_name = "小型磁轨炮"
	w.description = "高速磁轨炮，每发造成 %d 伤害" % 30
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
	w.quality = 1
	return w

static func _small_laser() -> ShopItemData:
	var w = ShopItemData.new()
	w.shop_item_id = ShopItemID.SMALL_LASER
	w.equip_type = EquipType.WEAPON
	w.display_name = "小型激光束"
	w.description = "持续激光束，每 0.7 秒造成 %d 伤害，穿透所有敌人" % 10
	w.star_coin_price = 2500
	w.mineral_tier = MineralTier.MID
	w.mineral_count = 0
	w.sell_price = 1000
	w.base_damage = 10.0
	w.fire_interval = 2.5
	w.range = 700.0
	w.crit_rate = 0.08
	w.crit_mult = 1.6
	w.scene_path = "res://scenes/LaserBeam.tscn"
	w.shield_bonus = 0.0
	w.shield_regen_bonus = 0.0
	w.quality = 1
	return w

static func _small_shield_optimizer() -> ShopItemData:
	var e = ShopItemData.new()
	e.shop_item_id = ShopItemID.SMALL_SHIELD_OPTIMIZER
	e.equip_type = EquipType.ARMOR
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

static func _small_shield_regen() -> ShopItemData:
	var e = ShopItemData.new()
	e.shop_item_id = ShopItemID.SMALL_SHIELD_REGEN
	e.equip_type = EquipType.ARMOR
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

func to_inventory_dict() -> Dictionary:
	return {
		"equip_id": str(ShopItemID.keys()[shop_item_id]) + "_" + str(Time.get_ticks_msec()),
		"equip_type": ShopItemData.EquipType.keys()[equip_type],
		"shop_item_id": shop_item_id,
		"quality": 0,
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
	}
