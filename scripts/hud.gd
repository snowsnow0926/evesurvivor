extends Control

const RaceData = preload("res://resources/race_data.gd")
const ShipData = preload("res://resources/ship_data.gd")
const WeaponData = preload("res://resources/weapon_data.gd")
const EquipmentData = preload("res://resources/equipment_data.gd")
const PlayerStats = preload("res://resources/player_stats.gd")

const UPGRADE_NAME_MAP: Dictionary = {
	"damage": "伤害强化",
	"shield_max": "临时护盾",
	"shield_regen": "护盾充能",
	"fire_coverage": "火力覆盖",
	"silent_hunter": "静默猎手",
	"precision_kill": "精准猎杀",
	"cannon_bloodthirst": "嗜血残暴",
	"cannon_rush": "狂飙突进",
	"cannon_vengeance": "为了部落",
	"railgun_damage": "一发入魂",
	"railgun_crit": "命中注定",
	"railgun_multi": "多重射击",
	"laser_duration": "高能光束",
	"laser_width": "高效射击",
	"laser_shield": "护盾中和",
}

const DEBUG := false

func _debug(msg: String) -> void:
	if DEBUG:
		print("[HUD] ", msg)

@onready var main_panel: PanelContainer = $BottomCenterAnchor/MainPanel
@onready var hp_bar: ProgressBar = $BottomCenterAnchor/MainPanel/VBox/HPRow/HPBar
@onready var hp_label: Label = $BottomCenterAnchor/MainPanel/VBox/HPRow/HPLabel
@onready var xp_bar: ProgressBar = $BottomCenterAnchor/MainPanel/VBox/XPRow/XPBar
@onready var xp_label: Label = $BottomCenterAnchor/MainPanel/VBox/XPRow/XPLabel
@onready var info_label: Label = $BottomCenterAnchor/MainPanel/VBox/InfoLabel
@onready var coin_gain_label: Label = $BottomCenterAnchor/MainPanel/VBox/CoinGainHBox/CoinGainLabel
@onready var combo_label: Label = $BottomCenterAnchor/MainPanel/VBox/ComboLabel

@onready var ship_panel: PanelContainer = $ShipInfoPanel
@onready var ship_title: Label = $ShipInfoPanel/ShipInfoVBox/ShipTitle
@onready var ship_hp_label: Label = $ShipInfoPanel/ShipInfoVBox/HPLabel
@onready var ship_shield_label: Label = $ShipInfoPanel/ShipInfoVBox/ShieldLabel
@onready var ship_atk_label: Label = $ShipInfoPanel/ShipInfoVBox/AtkLabel
@onready var ship_firerate_label: Label = $ShipInfoPanel/ShipInfoVBox/FireRateLabel
@onready var ship_speed_label: Label = $ShipInfoPanel/ShipInfoVBox/SpeedLabel
@onready var ship_crit_label: Label = $ShipInfoPanel/ShipInfoVBox/CritLabel
@onready var ship_dodge_label: Label = $ShipInfoPanel/ShipInfoVBox/DodgeLabel
@onready var race_info_label: Label = $ShipInfoPanel/ShipInfoVBox/RaceInfoLabel
@onready var race_bonus_label: Label = $ShipInfoPanel/ShipInfoVBox/RaceBonusLabel
@onready var ship_slots_label: Label = $ShipInfoPanel/ShipInfoVBox/ShipSlotsLabel

@onready var top_weapon_panel: PanelContainer = $TopCenterAnchor/TopWeaponPanel
@onready var top_slot1_name: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot1/WeaponSlot1VBox/Name
@onready var top_slot2: PanelContainer = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot2
@onready var top_slot2_name: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot2/WeaponSlot2VBox/Name
@onready var top_slot3: PanelContainer = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot3
@onready var top_slot3_name: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot3/WeaponSlot3VBox/Name
@onready var top_slot4: PanelContainer = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot4
@onready var top_slot4_name: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot4/WeaponSlot4VBox/Name
@onready var top_slot5: PanelContainer = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot5
@onready var top_slot5_name: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot5/WeaponSlot5VBox/Name
@onready var top_slot6: PanelContainer = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot6
@onready var top_slot6_name: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot6/WeaponSlot6VBox/Name
@onready var top_defense1: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot1/DefenseSlot1VBox/Name
@onready var top_defense2: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot2/DefenseSlot2VBox/Name
@onready var top_defense3: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot3/DefenseSlot3VBox/Name
@onready var top_defense4: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot4/DefenseSlot4VBox/Name
@onready var top_defense5: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot5/DefenseSlot5VBox/Name

@onready var upgrade_list_vbox: VBoxContainer = $BottomRightAnchor/UpgradeListPanel/UpgradeListVBox

@onready var timer_label: Label = $TopRightAnchor/TimerLabel

var game_scene: Node2D
var _vbox_warned: bool = false
var _prev_coin_display: int = -1
var _coin_floating_timer: float = 0.0
var _coin_floating_amount: int = 0
var _coin_gain_to_show: int = 0
var _coin_gain_timer: float = 0.0
const _COIN_GAIN_SHOW_DURATION := 2.0

func _ready() -> void:
	MobileInput.register_joystick($VirtualJoystick)
	if not upgrade_list_vbox:
		_debug("WARNING: upgrade_list_vbox is null! Node path may be wrong.")
		return
	if main_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.2, 0.9)
		style.set_border_width_all(2)
		style.border_color = Color(0.5, 0.5, 1.0)
		style.set_corner_radius_all(8)
		main_panel.add_theme_stylebox_override("panel", style)

	if ship_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.05, 0.05, 0.15, 0.9)
		style.set_border_width_all(2)
		style.border_color = Color(0.2, 0.5, 0.8)
		style.set_corner_radius_all(8)
		ship_panel.add_theme_stylebox_override("panel", style)

	if race_info_label:
		race_info_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	if race_bonus_label:
		race_bonus_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
		race_bonus_label.add_theme_font_size_override("font_size", 12)
	if ship_slots_label:
		ship_slots_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
		ship_slots_label.add_theme_font_size_override("font_size", 12)

	var equip_style = func(p: PanelContainer):
		var s = StyleBoxFlat.new()
		s.bg_color = Color(0.1, 0.15, 0.3, 0.9)
		s.set_border_width_all(2)
		s.border_color = Color(0.5, 0.7, 1.0)
		s.set_corner_radius_all(6)
		p.add_theme_stylebox_override("panel", s)

	if top_weapon_panel:
		var s = StyleBoxFlat.new()
		s.bg_color = Color(0.05, 0.05, 0.15, 0.85)
		s.set_border_width_all(2)
		s.border_color = Color(0.3, 0.4, 0.7)
		s.set_corner_radius_all(6)
		top_weapon_panel.add_theme_stylebox_override("panel", s)
		for slot_path in [
			"TopWeaponHBox/WeaponSlot1", "TopWeaponHBox/WeaponSlot2",
			"TopWeaponHBox/WeaponSlot3", "TopWeaponHBox/WeaponSlot4",
			"TopWeaponHBox/WeaponSlot5", "TopWeaponHBox/WeaponSlot6",
			"TopWeaponHBox/DefenseSlot1", "TopWeaponHBox/DefenseSlot2",
			"TopWeaponHBox/DefenseSlot3", "TopWeaponHBox/DefenseSlot4",
			"TopWeaponHBox/DefenseSlot5"
		]:
			var slot = top_weapon_panel.get_node_or_null(slot_path)
			if slot:
				equip_style.call(slot)

	var upgrade_panel = $BottomRightAnchor/UpgradeListPanel
	if upgrade_panel:
		var s = StyleBoxFlat.new()
		s.bg_color = Color(0.05, 0.05, 0.15, 0.85)
		s.set_border_width_all(2)
		s.border_color = Color(0.3, 0.5, 0.8)
		s.set_corner_radius_all(6)
		upgrade_panel.add_theme_stylebox_override("panel", s)
	if upgrade_list_vbox:
		var title_lbl = upgrade_list_vbox.get_node_or_null("TitleLabel")
		if title_lbl:
			title_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
			title_lbl.add_theme_font_size_override("font_size", 14)
	if upgrade_list_vbox:
		upgrade_list_vbox.custom_minimum_size.y = 30

func _process(delta: float) -> void:
	if _coin_floating_timer > 0.0:
		_coin_floating_timer -= delta
		if _coin_floating_timer <= 0.0:
			_coin_floating_timer = 0.0
	if _coin_gain_timer > 0.0:
		_coin_gain_timer -= delta
		if _coin_gain_timer <= 0.0:
			_coin_gain_timer = 0.0
			_coin_gain_to_show = 0
	if not game_scene or not game_scene.game_manager:
		return
	var gm = game_scene.game_manager
	var player = gm.player if (gm.player and is_instance_valid(gm.player)) else null

	var all_weapon_data: Array = []
	if player:
		if player.get("active_weapons"):
			var weapons: Array = player.get("active_weapons")
			if weapons:
				for w in weapons:
					if w:
						all_weapon_data.append({
							"name": w.display_name,
							"level": _get_weapon_upgrade_level(w.weapon_id),
							"quality": w.quality,
						})

	var defense_list: Array = []
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE
	var armor_list: Array = GameState.equipped_armor.get(ship_id, [])
	if not (armor_list is Array):
		armor_list = []
	for armor in armor_list:
		if armor is Dictionary:
			defense_list.append({
				"name": armor.get("name", "防御装"),
				"level": armor.get("level", 1),
				"quality": armor.get("quality", 0),
			})

	update_display(
		gm.player_stats.hp,
		gm.player_stats.max_hp,
		gm.player_stats.shield,
		gm.player_stats.shield_max,
		GameState.star_coin,
		GameState.minerals_low + GameState.minerals_mid + GameState.minerals_high,
		gm.kill_count,
		gm.current_xp,
		gm.xp_to_next_level,
		gm.player_level,
		gm.combo_count
	)
	_update_timer_display(gm)
	_update_top_weapon_display(all_weapon_data, defense_list)
	_update_race_and_ship_display()
	_update_upgrade_list_display(gm)
	if ship_hp_label:
		ship_hp_label.text = "HP: %d / %d" % [gm.player_stats.hp, gm.player_stats.max_hp]
	if ship_shield_label:
		ship_shield_label.text = "护盾: %.0f / %.0f" % [gm.player_stats.shield, gm.player_stats.shield_max]
	if ship_atk_label:
		ship_atk_label.text = "攻击: %.1f" % gm.player_stats.damage
	if ship_firerate_label:
		var primary_fire_interval = 0.8
		if player and player.get("active_weapons"):
			var weapons = player.get("active_weapons") as Array
			if weapons and not weapons.is_empty():
				var pw = weapons[0]
				if pw:
					primary_fire_interval = pw.fire_interval
		ship_firerate_label.text = "射速: %.2fs" % primary_fire_interval
	if ship_speed_label:
		ship_speed_label.text = "移速: %.0f" % gm.player_stats.move_speed
	if ship_crit_label:
		ship_crit_label.text = "暴击: %.0f%%" % (gm.player_stats.crit_rate * 100.0)
	if ship_dodge_label:
		ship_dodge_label.text = "闪避: %.0f%%" % (gm.player_stats.dodge * 100.0)

func _get_weapon_upgrade_level(weapon_id) -> int:
	var upgrade_ids = _get_upgrade_ids_for_weapon(weapon_id)
	if upgrade_ids.is_empty():
		return 0
	var total = 0
	var gm = game_scene.game_manager if game_scene else null
	if not gm:
		return 0
	for uid in upgrade_ids:
		total += gm.upgrade_counts.get(uid, 0)
	return total

func _get_upgrade_ids_for_weapon(wid) -> Array:
	var missile_ids = [
		WeaponData.WeaponID.MISSILE, WeaponData.WeaponID.SMALL_MISSILE,
		WeaponData.WeaponID.MEDIUM_MISSILE, WeaponData.WeaponID.LARGE_MISSILE, WeaponData.WeaponID.FLAGSHIP_MISSILE
	]
	var cannon_ids = [
		WeaponData.WeaponID.CANNON, WeaponData.WeaponID.SMALL_CANNON,
		WeaponData.WeaponID.MEDIUM_CANNON, WeaponData.WeaponID.LARGE_CANNON, WeaponData.WeaponID.FLAGSHIP_CANNON
	]
	var railgun_ids = [
		WeaponData.WeaponID.RAILGUN, WeaponData.WeaponID.SMALL_RAILGUN,
		WeaponData.WeaponID.MEDIUM_RAILGUN, WeaponData.WeaponID.LARGE_RAILGUN, WeaponData.WeaponID.FLAGSHIP_RAILGUN
	]
	var laser_ids = [
		WeaponData.WeaponID.LASER, WeaponData.WeaponID.SMALL_LASER,
		WeaponData.WeaponID.MEDIUM_LASER, WeaponData.WeaponID.LARGE_LASER, WeaponData.WeaponID.FLAGSHIP_LASER
	]
	if wid in missile_ids:
		return ["fire_coverage", "silent_hunter", "precision_kill"]
	elif wid in cannon_ids:
		return ["cannon_bloodthirst", "cannon_rush", "cannon_vengeance"]
	elif wid in railgun_ids:
		return ["railgun_multi", "railgun_crit", "railgun_damage"]
	elif wid in laser_ids:
		return ["laser_duration", "laser_width", "laser_shield"]
	return []

func _update_top_weapon_display(all_weapon_data: Array, defense_list: Array) -> void:
	var slot_nodes = [
		{"panel": null, "name_label": top_slot1_name},
		{"panel": null, "name_label": top_slot2_name},
		{"panel": null, "name_label": top_slot3_name},
		{"panel": null, "name_label": top_slot4_name},
		{"panel": null, "name_label": top_slot5_name},
		{"panel": null, "name_label": top_slot6_name},
	]
	slot_nodes[0]["panel"] = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot1
	slot_nodes[1]["panel"] = top_slot2
	slot_nodes[2]["panel"] = top_slot3
	slot_nodes[3]["panel"] = top_slot4
	slot_nodes[4]["panel"] = top_slot5
	slot_nodes[5]["panel"] = top_slot6

	for i in range(slot_nodes.size()):
		var slot = slot_nodes[i]
		var panel: Node = slot["panel"]
		var name_lbl: Label = slot["name_label"]
		if not panel or not name_lbl:
			continue
		if i < all_weapon_data.size():
			var wd = all_weapon_data[i]
			panel.visible = true
			name_lbl.text = "%s" % wd.get("name", "?")
			name_lbl.add_theme_color_override("font_color", EquipmentData.get_quality_color(wd.get("quality", 0)))
		else:
			panel.visible = false

	var defense_slots = [top_defense1, top_defense2, top_defense3, top_defense4, top_defense5]
	for idx in range(defense_slots.size()):
		var name_lbl: Label = defense_slots[idx]
		if not name_lbl:
			continue
		var slot_panel: Node = null
		match idx:
			0: slot_panel = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot1
			1: slot_panel = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot2
			2: slot_panel = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot3
			3: slot_panel = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot4
			4: slot_panel = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot5
		if slot_panel:
			slot_panel.visible = (idx < defense_list.size())
		if idx < defense_list.size():
			var armor = defense_list[idx]
			name_lbl.text = "%s" % armor.get("name", "防御装")
			name_lbl.add_theme_color_override("font_color", EquipmentData.get_quality_color(armor.get("quality", 0)))
		else:
			name_lbl.text = "空槽位"
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

func _update_upgrade_list_display(gm) -> void:
	if not upgrade_list_vbox:
		if not _vbox_warned:
			_debug("_update_upgrade_list_display: upgrade_list_vbox is null!")
			_vbox_warned = true
		return

	var current_keys = gm.upgrade_counts.keys()
	var has_any_upgrade = false
	for k in current_keys:
		if gm.upgrade_counts[k] > 0:
			has_any_upgrade = true
			break

	# Ensure panel visibility tracks upgrade state
	var upgrade_panel = $BottomRightAnchor/UpgradeListPanel
	if upgrade_panel:
		upgrade_panel.visible = has_any_upgrade

	var existing_labels: Array = []
	for i in range(2, upgrade_list_vbox.get_child_count()):
		var child = upgrade_list_vbox.get_child(i)
		if child is Label:
			existing_labels.append(child)

	var label_idx = 0
	for key in current_keys:
		var count = gm.upgrade_counts.get(key, 0)
		if count <= 0:
			continue
		var display_name = UPGRADE_NAME_MAP.get(key, key)
		var text = "%s Lv.%d" % [display_name, count]

		var lbl: Label
		if label_idx < existing_labels.size():
			lbl = existing_labels[label_idx]
			lbl.text = text
			lbl.visible = true
		else:
			lbl = Label.new()
			lbl.text = text
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
			upgrade_list_vbox.add_child(lbl)
		label_idx += 1

	for i in range(label_idx, existing_labels.size()):
		existing_labels[i].visible = false

func update_display(p_hp: int, p_max_hp: int, p_shield: float, p_shield_max: float, p_coin: int, p_minerals: int, p_kills: int, p_xp: float, p_xp_max: float, p_level: int, p_combo: int = 0) -> void:
	if hp_bar:
		hp_bar.max_value = maxf(p_max_hp, 1.0)
		hp_bar.value = clampf(p_hp, 0, p_max_hp)
		hp_bar.add_theme_color_override("fill", Color(1, 0.2, 0.2))
	if hp_label:
		hp_label.text = "HP: %d" % p_hp

	if xp_bar:
		xp_bar.max_value = maxf(p_xp_max, 1.0)
		xp_bar.value = clampf(p_xp, 0, p_xp_max)
		xp_bar.add_theme_color_override("fill", Color(0.2, 0.8, 0.2))
	if xp_label:
		xp_label.text = "XP: %.0f / %.0f" % [p_xp, p_xp_max]

	if info_label:
		info_label.text = "Level: %d | Kills: %d | 星币: %d" % [p_level, p_kills, p_coin]
		info_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	if _prev_coin_display >= 0 and p_coin > _prev_coin_display:
		_coin_floating_amount += (p_coin - _prev_coin_display)
		if _coin_floating_timer <= 0.0:
			_coin_floating_timer = 0.6
			_coin_gain_to_show = _coin_floating_amount
			_coin_gain_timer = _COIN_GAIN_SHOW_DURATION
			_spawn_coin_floating_text(_coin_floating_amount)
			_coin_floating_amount = 0
	_prev_coin_display = p_coin

	if coin_gain_label:
		if _coin_gain_to_show > 0 and _coin_gain_timer > 0.0:
			coin_gain_label.text = "+%d" % _coin_gain_to_show
			coin_gain_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
			coin_gain_label.add_theme_font_size_override("font_size", 16)
		else:
			coin_gain_label.text = ""

	if combo_label:
		if p_combo >= 3:
			combo_label.text = "x%d COMBO!" % p_combo
			if p_combo >= 10:
				combo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
				combo_label.add_theme_font_size_override("font_size", 18)
			elif p_combo >= 5:
				combo_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
				combo_label.add_theme_font_size_override("font_size", 16)
			else:
				combo_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
				combo_label.add_theme_font_size_override("font_size", 14)
		else:
			combo_label.text = ""

func _update_race_and_ship_display() -> void:
	if not game_scene or not game_scene.game_manager:
		return
	var gm = game_scene.game_manager
	if not gm.player or not is_instance_valid(gm.player):
		return

	if race_info_label:
		var race = RaceData.get_race(GameState.selected_race_id)
		if race:
			race_info_label.text = "种族: " + race.display_name
		else:
			race_info_label.text = "种族: -"

	if race_bonus_label:
		var race = RaceData.get_race(GameState.selected_race_id)
		if race and race.talents.size() > 0:
			var lines: Array = []
			for talent in race.talents:
				lines.append("%s Lv.%d" % [talent.get("name", "?"), int(talent.get("value", 1))])
			race_bonus_label.text = "天赋: " + "\n".join(lines)
		else:
			race_bonus_label.text = "天赋: -"

	if ship_slots_label:
		var ship = ShipData.get_ship(GameState.selected_ship_id)
		if ship:
			var ship_id = int(GameState.selected_ship_id)
			if ship_id == 0:
				ship_id = ShipData.ShipID.FRIGATE
			var weapon_list = GameState.equipped_weapons.get(ship_id, [])
			var weapon_count = 0
			if weapon_list is Array:
				weapon_count = weapon_list.size()
			var w_max = ship.upgraded_weapon_slots if GameState.upgraded_ships.get(ship_id, false) else ship.weapon_slot_count
			var armor_count = 0
			var armor_list: Array = GameState.equipped_armor.get(ship_id, [])
			if armor_list is Array:
				armor_count = armor_list.size()
			var a_max = ship.upgraded_armor_slots if GameState.upgraded_ships.get(ship_id, false) else ship.armor_slot_count
			ship_slots_label.text = "武:%d/%d | 防:%d/%d" % [weapon_count, w_max, armor_count, a_max]
		else:
			ship_slots_label.text = "武:0/? | 防:0/?"

func setup(gs: Node2D) -> void:
	game_scene = gs
	_prev_coin_display = -1
	_coin_floating_timer = 0.0
	_coin_floating_amount = 0
	_coin_gain_to_show = 0
	_coin_gain_timer = 0.0
	update_display(100, 100, 50.0, 50.0, 0, 0, 0, 0.0, 10.0, 1)

func _update_timer_display(gm) -> void:
	if not timer_label:
		return
	if not gm.has_timer:
		timer_label.visible = false
		return

	if gm.is_unlimited_mode:
		# 无限时模式：正数向上计时
		var elapsed: float = gm.run_time_elapsed
		var mins := int(elapsed) / 60
		var secs := int(elapsed) % 60
		timer_label.text = "+%02d:%02d" % [mins, secs]
		timer_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		timer_label.visible = true
	elif gm.time_remaining > 0:
		# 首通倒计时模式
		var mins := int(gm.time_remaining) / 60
		var secs := int(gm.time_remaining) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
		timer_label.visible = true
		if gm.time_remaining <= 30.0:
			timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		elif gm.time_remaining <= 60.0:
			timer_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
		else:
			timer_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	else:
		timer_label.visible = false

func _spawn_coin_floating_text(amount: int) -> void:
	if not info_label:
		return
	var label = Label.new()
	label.text = "+%d" % amount
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.offset_top = info_label.global_position.y - 20.0
	label.offset_left = info_label.global_position.x + 60.0
	label.offset_right = label.offset_left + 200.0
	label.offset_bottom = label.offset_top + 30.0
	add_child(label)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "offset_top", label.offset_top - 30.0, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)

	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.7
	timer.timeout.connect(label.queue_free)
	add_child(timer)
	timer.start()
