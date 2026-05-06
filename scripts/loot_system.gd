class_name LootSystem
extends Node

## Manages loot drops, equipment generation, and reward granting.

var game_manager: Node2D

var session_loot: Array = []
var session_star_coin: int = 0
var session_minerals: int = 0

const DROP_ARMOR: Array[int] = [0, 1]

const StageData = preload("res://resources/stage_data.gd")
const WeaponData = preload("res://resources/weapon_data.gd")
const ShopItemData = preload("res://resources/shop_data.gd")

func _init(gm: Node2D) -> void:
	game_manager = gm

func try_drop_equipment(enemy: Node2D) -> void:
	var loot_chapter: int = enemy._get_loot_tonnage_chapter() if enemy.has_method("_get_loot_tonnage_chapter") else game_manager.current_chapter_id
	var loot := StageData.get_chapter_loot(loot_chapter)
	if randf() > loot.drop_rate:
		return
	var quality := _roll_equipment_quality(loot.quality_weights)
	var loot_type: String = "weapon" if randf() < 0.7 else "armor"
	var loot_data: Dictionary = {}
	if loot_type == "weapon":
		var wid := _get_random_weapon_id(loot.equipment_tier)
		var sid := _weapon_id_to_shop_id(wid)
		var shop_item = ShopItemData.get_item(sid)
		loot_data = {
			"equip_id": "w_%d_%d" % [sid, randi() % 100000],
			"type": "weapon",
			"weapon_id": sid,
			"scene_path": shop_item.scene_path,
			"quality": quality,
			"name": shop_item.display_name,
			"base_damage": shop_item.base_damage,
			"fire_interval": shop_item.fire_interval,
			"range": shop_item.range,
			"crit_rate": shop_item.crit_rate,
			"crit_mult": shop_item.crit_mult,
			"tonnage_tier": loot.equipment_tier,
			"pos": enemy.global_position
		}
	else:
		var aid := DROP_ARMOR[randi() % DROP_ARMOR.size()]
		loot_data = {"equip_id": "a_%d_%d" % [aid, randi() % 100000], "type": "armor", "armor_id": aid, "quality": quality, "pos": enemy.global_position}
	add_loot(loot_data)
	_spawn_loot_effect(enemy.global_position, loot_type)

func spawn_boss_loot(boss_node: Node2D) -> void:
	var loot_chapter: int = boss_node._get_loot_tonnage_chapter() if boss_node.has_method("_get_loot_tonnage_chapter") else game_manager.current_chapter_id
	var loot := StageData.get_chapter_loot(loot_chapter)
	var quality := _roll_equipment_quality(loot.quality_weights)
	var loot_type: String = "weapon" if randf() < 0.7 else "armor"
	var loot_data: Dictionary = {}
	if loot_type == "weapon":
		var wid := _get_random_weapon_id(loot.equipment_tier)
		var sid := _weapon_id_to_shop_id(wid)
		var shop_item = ShopItemData.get_item(sid)
		loot_data = {
			"equip_id": "w_%d_%d" % [sid, randi() % 100000],
			"type": "weapon",
			"weapon_id": sid,
			"scene_path": shop_item.scene_path,
			"quality": quality,
			"name": shop_item.display_name,
			"base_damage": shop_item.base_damage,
			"fire_interval": shop_item.fire_interval,
			"range": shop_item.range,
			"crit_rate": shop_item.crit_rate,
			"crit_mult": shop_item.crit_mult,
			"tonnage_tier": loot.equipment_tier,
			"pos": boss_node.global_position
		}
	else:
		var aid := DROP_ARMOR[randi() % DROP_ARMOR.size()]
		loot_data = {"equip_id": "a_%d_%d" % [aid, randi() % 100000], "type": "armor", "armor_id": aid, "quality": quality, "pos": boss_node.global_position}
	add_loot(loot_data)
	_spawn_loot_effect(boss_node.global_position, loot_type)

func on_enemy_killed(enemy: Node2D, enemy_type: String) -> int:
	var loot_chapter: int = enemy._get_loot_tonnage_chapter() if enemy.has_method("_get_loot_tonnage_chapter") else game_manager.current_chapter_id
	var loot := StageData.get_chapter_loot(loot_chapter)
	var multiplier: float = game_manager.difficulty_scaler.combo_multiplier if game_manager.difficulty_scaler else 1.0
	var reward_coin := int(loot.get_coin(enemy_type) * multiplier)
	var reward_mineral := int(_scale_mineral(loot.get_mineral(enemy_type), loot.get_mineral_tier(enemy_type)) * multiplier)
	session_star_coin += reward_coin
	session_minerals += reward_mineral
	return reward_coin

func on_boss_killed(boss_node: Node2D) -> void:
	var loot_chapter: int = boss_node._get_loot_tonnage_chapter() if boss_node.has_method("_get_loot_tonnage_chapter") else game_manager.current_chapter_id
	var loot := StageData.get_chapter_loot(loot_chapter)
	var reward_coin := loot.get_coin("boss")
	var reward_mineral := int(_scale_mineral(loot.get_mineral("boss"), loot.get_mineral_tier("boss")))
	session_star_coin += reward_coin
	session_minerals += reward_mineral

func add_loot(loot_data: Dictionary) -> void:
	session_loot.append(loot_data)

func get_session_loot() -> Array:
	return session_loot

func grant_loot_to_player() -> Array:
	var granted: Array = []
	for loot: Dictionary in session_loot:
		var item_dict := {
			"equip_id": loot.get("equip_id", ""),
			"type": loot.get("type", "weapon"),
			"weapon_id": loot.get("weapon_id", 0),
			"armor_id": loot.get("armor_id", 0),
			"quality": loot.get("quality", 0),
			"name": loot.get("name", "?"),
			"base_damage": loot.get("base_damage", 0.0),
			"fire_interval": loot.get("fire_interval", 1.0),
			"range": loot.get("range", 0.0),
			"crit_rate": loot.get("crit_rate", 0.0),
			"crit_mult": loot.get("crit_mult", 1.5),
			"tonnage_tier": loot.get("tonnage_tier", 0),
			"equip_type": loot.get("type", "weapon"),
			"scene_path": loot.get("scene_path", ""),
			"is_new": true,
		}
		granted.append(item_dict)
		GameState.equipment_inventory.append(item_dict)
	session_loot.clear()
	return granted

func reset() -> void:
	session_loot = []
	session_star_coin = 0
	session_minerals = 0

func _roll_equipment_quality(weights: Array) -> int:
	var roll := randf()
	var cumulative := 0.0
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return i
	return 0

func _get_random_weapon_id(tier: int) -> int:
	var pool: Array = []
	match tier:
		0:
			pool = [
				WeaponData.WeaponID.SMALL_MISSILE,
				WeaponData.WeaponID.SMALL_CANNON,
				WeaponData.WeaponID.SMALL_RAILGUN,
				WeaponData.WeaponID.SMALL_LASER,
			]
		1:
			pool = [
				WeaponData.WeaponID.MEDIUM_MISSILE,
				WeaponData.WeaponID.MEDIUM_CANNON,
				WeaponData.WeaponID.MEDIUM_RAILGUN,
				WeaponData.WeaponID.MEDIUM_LASER,
			]
		2:
			pool = [
				WeaponData.WeaponID.LARGE_MISSILE,
				WeaponData.WeaponID.LARGE_CANNON,
				WeaponData.WeaponID.LARGE_RAILGUN,
				WeaponData.WeaponID.LARGE_LASER,
			]
		3:
			pool = [
				WeaponData.WeaponID.FLAGSHIP_MISSILE,
				WeaponData.WeaponID.FLAGSHIP_CANNON,
				WeaponData.WeaponID.FLAGSHIP_RAILGUN,
				WeaponData.WeaponID.FLAGSHIP_LASER,
			]
		_:
			pool = [
				WeaponData.WeaponID.SMALL_MISSILE,
				WeaponData.WeaponID.SMALL_CANNON,
				WeaponData.WeaponID.SMALL_RAILGUN,
				WeaponData.WeaponID.SMALL_LASER,
			]
	return pool[randi() % pool.size()]

func _weapon_id_to_shop_id(wid: int) -> int:
	var mapping: Dictionary = {
		WeaponData.WeaponID.SMALL_MISSILE: ShopItemData.ShopItemID.SMALL_MISSILE,
		WeaponData.WeaponID.SMALL_CANNON: ShopItemData.ShopItemID.SMALL_CANNON,
		WeaponData.WeaponID.SMALL_RAILGUN: ShopItemData.ShopItemID.SMALL_RAILGUN,
		WeaponData.WeaponID.SMALL_LASER: ShopItemData.ShopItemID.SMALL_LASER,
		WeaponData.WeaponID.MEDIUM_MISSILE: ShopItemData.ShopItemID.MEDIUM_MISSILE,
		WeaponData.WeaponID.MEDIUM_CANNON: ShopItemData.ShopItemID.MEDIUM_CANNON,
		WeaponData.WeaponID.MEDIUM_RAILGUN: ShopItemData.ShopItemID.MEDIUM_RAILGUN,
		WeaponData.WeaponID.MEDIUM_LASER: ShopItemData.ShopItemID.MEDIUM_LASER,
		WeaponData.WeaponID.LARGE_MISSILE: ShopItemData.ShopItemID.LARGE_MISSILE,
		WeaponData.WeaponID.LARGE_CANNON: ShopItemData.ShopItemID.LARGE_CANNON,
		WeaponData.WeaponID.LARGE_RAILGUN: ShopItemData.ShopItemID.LARGE_RAILGUN,
		WeaponData.WeaponID.LARGE_LASER: ShopItemData.ShopItemID.LARGE_LASER,
		WeaponData.WeaponID.FLAGSHIP_MISSILE: ShopItemData.ShopItemID.FLAGSHIP_MISSILE,
		WeaponData.WeaponID.FLAGSHIP_CANNON: ShopItemData.ShopItemID.FLAGSHIP_CANNON,
		WeaponData.WeaponID.FLAGSHIP_RAILGUN: ShopItemData.ShopItemID.FLAGSHIP_RAILGUN,
		WeaponData.WeaponID.FLAGSHIP_LASER: ShopItemData.ShopItemID.FLAGSHIP_LASER,
	}
	return mapping.get(wid, ShopItemData.ShopItemID.SMALL_MISSILE)

func _spawn_loot_effect(world_pos: Vector2, loot_type: String) -> void:
	var dmg_root = game_manager.get("damage_root")
	if not dmg_root or not is_instance_valid(dmg_root):
		return
	var label := Label.new()
	label.text = "[%s]" % ("武器" if loot_type == "weapon" else "防具")
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	label.position = world_pos + Vector2(randf_range(-30, 30), -40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dmg_root.call_deferred("add_child", label)
	var tween := game_manager.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 60, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)

func _scale_mineral(base: int, tier: StageData.LootTier) -> float:
	match tier:
		StageData.LootTier.LOW: return base as float
		StageData.LootTier.MEDIUM: return base as float * 1.5
		StageData.LootTier.HIGH: return base as float * 2.5
	return base as float
