extends Control

const RaceData = preload("res://resources/race_data.gd")
const ShipData = preload("res://resources/ship_data.gd")

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

@onready var weapon_panel: HBoxContainer = $WeaponPanel
@onready var weapon_slot1: PanelContainer = $WeaponPanel/WeaponSlot1
@onready var weapon_slot2: PanelContainer = $WeaponPanel/WeaponSlot2
@onready var weapon_slot1_name: Label = $WeaponPanel/WeaponSlot1/WeaponSlot1VBox/Name
@onready var weapon_slot2_name: Label = $WeaponPanel/WeaponSlot2/WeaponSlot2VBox/Name

@onready var timer_label: Label = $TopRightAnchor/TimerLabel

var game_scene: Node2D

func _ready() -> void:
	print("[HUD] _ready called")
	print("[HUD] main_panel visible=", main_panel.visible if main_panel else "N/A")
	print("[HUD] rect=", get_global_rect())
	
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

	if weapon_slot1:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.2, 0.85)
		style.set_border_width_all(2)
		style.border_color = Color(0.4, 0.6, 1.0)
		style.set_corner_radius_all(6)
		weapon_slot1.add_theme_stylebox_override("panel", style)
	if weapon_slot2:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.2, 0.85)
		style.set_border_width_all(2)
		style.border_color = Color(0.4, 0.6, 1.0)
		style.set_corner_radius_all(6)
		weapon_slot2.add_theme_stylebox_override("panel", style)

func setup(gs: Node2D) -> void:
	game_scene = gs
	print("[HUD] setup called")
	update_display(100, 100, 50.0, 50.0, 0, 0, 0, 0.0, 10.0, 1)

func _process(_delta: float) -> void:
	if not game_scene or not game_scene.game_manager:
		return
	var gm = game_scene.game_manager

	var primary_name = "武器"
	if game_scene and game_scene.game_manager and game_scene.game_manager.player and is_instance_valid(game_scene.game_manager.player):
		var p = game_scene.game_manager.player
		if p.has_method("get_primary_weapon"):
			var pw = p.get_primary_weapon()
			if pw:
				primary_name = pw.display_name

	var secondary_name = null
	if game_scene and game_scene.game_manager and game_scene.game_manager.player and is_instance_valid(game_scene.game_manager.player):
		var p = game_scene.game_manager.player
		if p.has_method("get_secondary_weapon"):
			var sw = p.get_secondary_weapon()
			if sw:
				secondary_name = sw

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
	_update_weapon_display(primary_name, secondary_name)
	_update_ship_panel(gm)
	_update_race_and_ship_display()

func _update_ship_panel(gm) -> void:
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

func _update_weapon_display(primary: String, secondary = null) -> void:
	if weapon_slot1_name:
		weapon_slot1_name.text = primary

	var secondary_name = ""
	if secondary:
		secondary_name = secondary.display_name
	elif game_scene and game_scene.game_manager and game_scene.game_manager.player and is_instance_valid(game_scene.game_manager.player):
		var p = game_scene.game_manager.player
		if p.has_method("get_secondary_weapon"):
			var sw = p.get_secondary_weapon()
			if sw:
				secondary_name = sw.display_name

	if weapon_slot2_name:
		weapon_slot2_name.text = secondary_name
	if weapon_slot2:
		weapon_slot2.visible = not secondary_name.is_empty()

	var primary_style = StyleBoxFlat.new()
	primary_style.bg_color = Color(0.1, 0.15, 0.3, 0.9)
	primary_style.set_border_width_all(2)
	primary_style.border_color = Color(0.6, 0.8, 1.0)
	primary_style.set_corner_radius_all(6)
	weapon_slot1.add_theme_stylebox_override("panel", primary_style)

	var secondary_style = StyleBoxFlat.new()
	secondary_style.bg_color = Color(0.1, 0.15, 0.3, 0.9)
	secondary_style.set_border_width_all(2)
	secondary_style.border_color = Color(0.6, 0.8, 1.0)
	secondary_style.set_corner_radius_all(6)
	weapon_slot2.add_theme_stylebox_override("panel", secondary_style)

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
