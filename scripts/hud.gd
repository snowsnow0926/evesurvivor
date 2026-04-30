extends Control

const RaceData = preload("res://resources/race_data.gd")
const ShipData = preload("res://resources/ship_data.gd")
const WeaponData = preload("res://resources/weapon_data.gd")
const EquipmentData = preload("res://resources/equipment_data.gd")

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

@onready var main_panel: PanelContainer = $TopRightAnchor/MainPanel
@onready var hp_bar: ProgressBar = $TopRightAnchor/MainPanel/VBox/HPRow/HPBar
@onready var hp_label: Label = $TopRightAnchor/MainPanel/VBox/HPRow/HPLabel
@onready var xp_bar: ProgressBar = $TopRightAnchor/MainPanel/VBox/XPRow/XPBar
@onready var xp_label: Label = $TopRightAnchor/MainPanel/VBox/XPRow/XPLabel
@onready var info_label: Label = $TopRightAnchor/MainPanel/VBox/InfoLabel

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
@onready var top_defense_name: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot/DefenseSlotVBox/Name

@onready var upgrade_list_vbox: VBoxContainer = $BottomRightAnchor/UpgradeListPanel/UpgradeListVBox

@onready var timer_label: Label = $TopRightAnchor/TimerLabel

var game_scene: Node2D
var _vbox_warned: bool = false

func _ready() -> void:
	if not upgrade_list_vbox:
		print("[HUD] WARNING: upgrade_list_vbox is null! Node path may be wrong.")
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
			"TopWeaponHBox/DefenseSlot"
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

func setup(gs: Node2D) -> void:
	game_scene = gs
	update_display(100, 100, 50.0, 50.0, 0, 0, 0, 0.0, 10.0, 1)

var _debug_process_count: int = 0

func _process(_delta: float) -> void:
	_debug_process_count += 1
	if _debug_process_count <= 3:
		print("[HUD._process] game_scene=", game_scene, " game_manager=", game_scene.game_manager if game_scene else "N/A", " upgrade_list_vbox=", upgrade_list_vbox)
	if not game_scene or not game_scene.game_manager:
		return
	var gm = game_scene.game_manager

	var primary_name = "空槽位"
	var primary_level = 0
	var primary_quality: int = 0
	if game_scene and game_scene.game_manager and game_scene.game_manager.player and is_instance_valid(game_scene.game_manager.player):
		var p = game_scene.game_manager.player
		if p.has_method("get_primary_weapon"):
			var pw = p.get_primary_weapon()
			if pw:
				primary_name = pw.display_name
				primary_level = _get_weapon_upgrade_level(pw.weapon_id)
				if "quality" in pw:
					primary_quality = pw.quality

	var secondary_name = "空槽位"
	var secondary_level = 0
	var secondary_quality: int = 0
	var has_secondary = false
	if game_scene and game_scene.game_manager and game_scene.game_manager.player and is_instance_valid(game_scene.game_manager.player):
		var p = game_scene.game_manager.player
		if p.has_method("get_secondary_weapon"):
			var sw = p.get_secondary_weapon()
			if sw:
				secondary_name = sw.display_name
				secondary_level = _get_weapon_upgrade_level(sw.weapon_id)
				if "quality" in sw:
					secondary_quality = sw.quality
				has_secondary = true

	var defense_name = "空槽位"
	var defense_level = 0
	var defense_quality: int = 0
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE
	var armor_dict = GameState.equipped_armor.get(ship_id, {})
	if armor_dict is Dictionary and not armor_dict.is_empty():
		defense_name = armor_dict.get("name", "防御装")
		defense_level = armor_dict.get("level", 1)
		defense_quality = armor_dict.get("quality", 0)

	update_display(
		gm.player_hp,
		gm.player_max_hp,
		gm.player_shield,
		gm.player_shield_max,
		GameState.star_coin,
		GameState.minerals_low + GameState.minerals_mid + GameState.minerals_high,
		gm.kill_count,
		gm.current_xp,
		gm.xp_to_next_level,
		gm.player_level,
		gm.combo_count
	)
	_update_timer_display(gm)
	_update_top_weapon_display(
		primary_name, primary_level, primary_quality,
		secondary_name, secondary_level, secondary_quality, has_secondary,
		defense_name, defense_level, defense_quality
	)
	_update_race_and_ship_display()
	_update_upgrade_list_display(gm)
	if ship_hp_label:
		ship_hp_label.text = "HP: %d / %d" % [gm.player_hp, gm.player_max_hp]
	if ship_shield_label:
		ship_shield_label.text = "护盾: %.0f / %.0f" % [gm.player_shield, gm.player_shield_max]
	if ship_atk_label:
		ship_atk_label.text = "攻击: %.1f" % gm.player_damage
	if ship_firerate_label:
		var primary_fire_interval = 0.8
		if game_scene and game_scene.game_manager and game_scene.game_manager.player and is_instance_valid(game_scene.game_manager.player):
			var p = game_scene.game_manager.player
			if p.get("active_weapons") and p.active_weapons.size() > 0:
				var pw = p.active_weapons[0]
				if pw:
					primary_fire_interval = pw.fire_interval
		ship_firerate_label.text = "射速: %.2fs" % primary_fire_interval
	if ship_speed_label:
		ship_speed_label.text = "移速: %.0f" % gm.player_move_speed
	if ship_crit_label:
		ship_crit_label.text = "暴击: %.0f%%" % (gm.player_crit_rate * 100.0)
	if ship_dodge_label:
		ship_dodge_label.text = "闪避: %.0f%%" % (gm.player_dodge * 100.0)

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
	match wid:
		WeaponData.WeaponID.MISSILE, WeaponData.WeaponID.SMALL_MISSILE:
			return ["fire_coverage", "silent_hunter", "precision_kill"]
		WeaponData.WeaponID.CANNON, WeaponData.WeaponID.SMALL_CANNON:
			return ["cannon_bloodthirst", "cannon_rush", "cannon_vengeance"]
		WeaponData.WeaponID.RAILGUN, WeaponData.WeaponID.SMALL_RAILGUN:
			return ["railgun_multi", "railgun_crit", "railgun_damage"]
		WeaponData.WeaponID.LASER, WeaponData.WeaponID.SMALL_LASER:
			return ["laser_duration", "laser_width", "laser_shield"]
	return []

func _update_top_weapon_display(primary: String, primary_lv: int, primary_q: int, secondary: String, secondary_lv: int, secondary_q: int, has_secondary: bool, defense: String, defense_lv: int, defense_q: int) -> void:
	if top_slot1_name:
		if primary == "空槽位":
			top_slot1_name.text = "空槽位"
			top_slot1_name.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		else:
			top_slot1_name.text = "%s Lv.%d" % [primary, primary_lv]
			top_slot1_name.add_theme_color_override("font_color", EquipmentData.get_quality_color(primary_q))

	if top_slot2:
		top_slot2.visible = has_secondary
		if top_slot2_name:
			if secondary == "空槽位":
				top_slot2_name.text = "空槽位"
				top_slot2_name.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			else:
				top_slot2_name.text = "%s Lv.%d" % [secondary, secondary_lv]
				top_slot2_name.add_theme_color_override("font_color", EquipmentData.get_quality_color(secondary_q))

	if top_defense_name:
		if defense == "空槽位":
			top_defense_name.text = "空槽位"
			top_defense_name.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		else:
			top_defense_name.text = "%s Lv.%d" % [defense, defense_lv]
			top_defense_name.add_theme_color_override("font_color", EquipmentData.get_quality_color(defense_q))

func _update_upgrade_list_display(gm) -> void:
	if not upgrade_list_vbox:
		if not _vbox_warned:
			print("[HUD] _update_upgrade_list_display: upgrade_list_vbox is null!")
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
		if has_any_upgrade and not upgrade_panel.visible:
			print("[HUD] UpgradeListPanel 显示! upgrade_counts=", gm.upgrade_counts)
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
		var combo_text = " | x%d COMBO!" % p_combo if p_combo >= 3 else ""
		info_label.text = "Level: %d | Kills: %d | Coin: %d%s" % [p_level, p_kills, p_coin, combo_text]
		if p_combo >= 10:
			info_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
		elif p_combo >= 5:
			info_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
		else:
			info_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

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
			var armor_dict = GameState.equipped_armor.get(ship_id, {})
			if armor_dict is Dictionary and not armor_dict.is_empty():
				armor_count = 1
			var a_max = ship.upgraded_armor_slots if GameState.upgraded_ships.get(ship_id, false) else ship.armor_slot_count
			ship_slots_label.text = "武:%d/%d | 防:%d/%d" % [weapon_count, w_max, armor_count, a_max]
		else:
			ship_slots_label.text = "武:0/? | 防:0/?"

func _update_timer_display(gm) -> void:
	if not timer_label:
		return
	if gm.has_timer and gm.time_remaining > 0:
		var mins = int(gm.time_remaining) / 60
		var secs = int(gm.time_remaining) % 60
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
