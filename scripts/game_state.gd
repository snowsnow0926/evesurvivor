extends Node

var selected_race_id: int = 0
var player_name: String = ""
var selected_ship_id: int = 1  # 默认护卫舰，避免与0值混淆
var unlocked_ships: Array = []
var equipment_inventory: Array = []
var equipped_weapons: Dictionary = {}
var equipped_armor: Dictionary = {}
var star_coin: int = 0
var minerals_low: int = 0
var minerals_mid: int = 0
var minerals_high: int = 0
var upgraded_ships: Dictionary = {}
var ship_damaged: bool = false
var total_kills: int = 0
var total_deaths: int = 0
var highest_level: int = 1
var first_run: bool = true
var last_run_reason: String = ""
var pre_run_coin: int = 0
var pre_run_minerals_total: int = 0

const REPAIR_COST_FRIGATE: int = 500
const REPAIR_COST_CRUISER: int = 2000
const REPAIR_COST_BATTLECRUISER: int = 5000
const REPAIR_COST_BATTLESHIP: int = 15000
const REPAIR_COST_DREADNOUGHT: int = 50000
const REPAIR_COST_TITAN: int = 200000

func _ready() -> void:
	pass

func get_repair_cost() -> int:
	var ship = ShipData.get_ship(selected_ship_id)
	if ship:
		return ship.repair_cost
	if selected_ship_id == 0:
		var frigate = ShipData.get_ship(ShipData.ShipID.FRIGATE)
		return frigate.repair_cost if frigate else 500
	return 500

func can_afford_repair() -> bool:
	return star_coin >= get_repair_cost()

func repair_ship() -> bool:
	if not ship_damaged:
		return false
	if star_coin < get_repair_cost():
		return false
	star_coin -= get_repair_cost()
	ship_damaged = false
	return true

func add_rewards(coin: int, minrl: int) -> void:
	star_coin += coin
	var low = int(minrl * 0.6)
	var mid = int(minrl * 0.3)
	var high = minrl - low - mid
	minerals_low += low
	minerals_mid += mid
	minerals_high += high

func on_run_started() -> void:
	if first_run:
		first_run = false
	pre_run_coin = star_coin
	pre_run_minerals_total = minerals_low + minerals_mid + minerals_high

func on_run_ended(kills: int, level: int, coin_gained: int, minerals_gained: int, was_dead: bool) -> void:
	total_kills += kills
	highest_level = max(highest_level, level)
	if was_dead:
		total_deaths += 1
		ship_damaged = true
		var dead_coins = int(coin_gained * 0.5)
		var dead_minerals = int(minerals_gained * 0.5)
		add_rewards(dead_coins, dead_minerals)
	else:
		add_rewards(coin_gained, minerals_gained)

func get_earned_coin() -> int:
	return star_coin - pre_run_coin

func get_earned_minerals() -> int:
	return (minerals_low + minerals_mid + minerals_high) - pre_run_minerals_total

func reset_progress() -> void:
	star_coin = 0
	minerals_low = 0
	minerals_mid = 0
	minerals_high = 0
	ship_damaged = false
	total_kills = 0
	total_deaths = 0
	highest_level = 1
	first_run = true
	last_run_reason = ""
	selected_race_id = 0
	selected_ship_id = 1
	unlocked_ships = []
	equipment_inventory = []
	equipped_weapons = {}
	equipped_armor = {}
	upgraded_ships = {}
