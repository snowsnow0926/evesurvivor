extends Node2D

const DEBUG := false

func _debug(msg: String) -> void:
	if DEBUG:
		print("[GameScene] ", msg)

const StageData = preload("res://resources/stage_data.gd")

var game_manager: Node2D
var is_settlement_open: bool = false

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_time: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("game_scene")
	is_settlement_open = false
	game_manager = $GameManager
	_setup_ui()
	_connect_signals()
	game_manager.setup_for_stage(GameState.selected_chapter_id, GameState.selected_stage_id)
	game_manager.start_run_timer()
	SoundManager.play_music("battle")
	_maybe_start_guide()

func _setup_ui() -> void:
	var ui_root = $UIRoot
	if ui_root:
		ui_root.process_mode = Node.PROCESS_MODE_ALWAYS
	var hud = $UIRoot/HUD
	if hud and hud.has_method("setup"):
		hud.setup(self)

	var upgrade_menu = $UIRoot/UpgradeMenu
	if upgrade_menu:
		upgrade_menu.visible = false

	var pause_menu = $UIRoot/PauseMenu
	if pause_menu:
		pause_menu.visible = false

	if hud and hud.speed_changed.get_connections().is_empty():
		hud.speed_changed.connect(_on_hud_speed_changed)

func _connect_signals() -> void:
	if game_manager:
		game_manager.upgrade_requested.connect(_on_upgrade_requested)
		game_manager.game_paused.connect(_on_pause_toggled)
		game_manager.player_dead.connect(_on_player_dead)
		game_manager.game_ended.connect(_on_game_ended)

	var upgrade_menu = $UIRoot/UpgradeMenu
	if upgrade_menu:
		upgrade_menu.upgrade_selected.connect(_on_upgrade_selected)

	var pause_menu_sig = $UIRoot/PauseMenu
	if pause_menu_sig:
		pause_menu_sig.retreat_requested.connect(_on_retreat_requested)
		pause_menu_sig.self_destruct_requested.connect(_on_self_destruct_requested)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if game_manager.is_upgrading or game_manager.is_game_over:
			return
		var pause_menu = $UIRoot/PauseMenu
		if pause_menu.is_open:
			pause_menu.close_menu()
		else:
			pause_menu.open_menu(game_manager)
		_notify_guide_pause()

	# 屏幕震动
	_update_screen_shake(_delta)

func _on_hud_speed_changed(speed: float) -> void:
	if game_manager and is_instance_valid(game_manager):
		game_manager.set_game_speed(speed)

func _on_upgrade_requested() -> void:
	SoundManager.play_sfx("upgrade")
	_notify_guide_level_up()
	var upgrade_menu = $UIRoot/UpgradeMenu
	if upgrade_menu:
		upgrade_menu.open_upgrade_menu(game_manager.upgrade_pool, game_manager)

func _on_upgrade_selected(upgrade_id: String) -> void:
	SoundManager.play_sfx("upgrade_select")
	game_manager.apply_upgrade(upgrade_id)

func _on_retreat_requested() -> void:
	SoundManager.play_sfx("retreat_success")
	game_manager.on_retreat()

func _on_player_dead() -> void:
	_show_settlement_screen("dead")

func _on_self_destruct_requested() -> void:
	_game_over_to_base()

func _on_pause_toggled(is_paused: bool) -> void:
	pass

func _on_game_ended(reason: String) -> void:
	get_tree().paused = false
	_show_settlement_screen(reason)

func _show_settlement_screen(reason) -> void:
	if is_settlement_open:
		return
	is_settlement_open = true

	SoundManager.play_music("settlement")

	var coin_gained = game_manager.session_star_coin
	game_manager.session_star_coin = 0
	var minerals_gained = game_manager.session_minerals
	var kills = game_manager.total_kills
	var level = game_manager.player_level

	var loot_for_settlement: Array = game_manager.get_session_loot().duplicate(true)

	_record_run_and_loot(reason, kills, level, coin_gained, minerals_gained)
	_handle_stage_progression(reason)

	get_tree().paused = false

	var settlement = _build_settlement_scene(reason, coin_gained, minerals_gained, kills, level, loot_for_settlement)
	if settlement == null:
		return

	var ui_root = $UIRoot
	if ui_root:
		ui_root.add_child(settlement)
	else:
		add_child(settlement)

	_connect_settlement_buttons(settlement)

func _record_run_and_loot(reason: String, kills: int, level: int, coin_gained: int, minerals_gained: int) -> void:
	match reason:
		"dead":
			GameState.last_run_reason = "dead"
			GameState.on_run_ended(kills, level, coin_gained, minerals_gained, true)
		"timeout":
			GameState.last_run_reason = "timeout"
			GameState.on_run_ended(kills, level, coin_gained, minerals_gained, true)
		"retreat":
			GameState.last_run_reason = "retreat"
			GameState.on_run_ended(kills, level, coin_gained, minerals_gained, false)
		"self_destruct":
			GameState.last_run_reason = "self_destruct"
			GameState.on_run_ended(kills, level, coin_gained, minerals_gained, true)
		"s6_victory":
			GameState.last_run_reason = "s6_victory"
			GameState.on_run_ended(kills, level, coin_gained, minerals_gained, false)
		_:
			GameState.last_run_reason = reason
			GameState.on_run_ended(kills, level, coin_gained, minerals_gained, false)

	var raw_loot: Array = game_manager.get_session_loot()
	for loot_item: Dictionary in raw_loot:
		var item_dict := {
			"equip_id": loot_item.get("equip_id", ""),
			"type": loot_item.get("type", "weapon"),
			"weapon_id": loot_item.get("weapon_id", 0),
			"armor_id": loot_item.get("armor_id", 0),
			"quality": loot_item.get("quality", 0),
			"name": loot_item.get("name", "?"),
			"base_damage": loot_item.get("base_damage", 0.0),
			"fire_interval": loot_item.get("fire_interval", 1.0),
			"range": loot_item.get("range", 0.0),
			"crit_rate": loot_item.get("crit_rate", 0.0),
			"crit_mult": loot_item.get("crit_mult", 1.5),
			"shield_bonus": loot_item.get("shield_bonus", 0.0),
			"shield_regen_bonus": loot_item.get("shield_regen_bonus", 0.0),
			"star_coin_price": loot_item.get("star_coin_price", 0),
			"tonnage_tier": loot_item.get("tonnage_tier", 0),
			"equip_type": loot_item.get("type", "weapon"),
			"scene_path": loot_item.get("scene_path", ""),
			"is_new": true,
		}
		GameState.equipment_inventory.append(item_dict)
	game_manager.get_session_loot().clear()

func _handle_stage_progression(reason: String) -> void:
	if reason == "s6_victory" and game_manager.current_stage != null:
		var cur_chapter: int = game_manager.current_chapter_id
		var cur_stage: int = game_manager.current_stage.id
		GameState.clear_stage(cur_chapter, cur_stage)
		match cur_chapter:
			1:
				GameState.unlock_chapter(2)
				GameState.unlock_stage(2, 1)
			2:
				GameState.unlock_chapter(3)
				GameState.unlock_stage(3, 1)
			3:
				GameState.unlock_chapter(4)
				GameState.unlock_stage(4, 1)
			4:
				GameState.unlock_chapter(5)
				GameState.unlock_stage(5, 1)
			5:
				GameState.unlock_chapter(6)
				GameState.unlock_stage(6, 1)
		return

	if reason == "retreat" and game_manager.current_stage != null:
		var cur_chapter: int = game_manager.current_chapter_id
		var cur_stage: int = game_manager.current_stage.id
		GameState.clear_stage(cur_chapter, cur_stage)
		if cur_stage == 6:
			match cur_chapter:
				1:
					GameState.unlock_chapter(2)
					GameState.unlock_stage(2, 1)
				2:
					GameState.unlock_chapter(3)
					GameState.unlock_stage(3, 1)
				3:
					GameState.unlock_chapter(4)
					GameState.unlock_stage(4, 1)
				4:
					GameState.unlock_chapter(5)
					GameState.unlock_stage(5, 1)
				5:
					GameState.unlock_chapter(6)
					GameState.unlock_stage(6, 1)
		else:
			GameState.unlock_stage(cur_chapter, cur_stage + 1)
		return

	if reason == "timeout" and game_manager.current_stage != null:
		var c_ch: int = game_manager.current_chapter_id
		var c_st: int = game_manager.current_stage.id
		if game_manager.elites_killed_this_run > 0:
			var changed := GameState.clear_stage(c_ch, c_st)
			_debug("First clear: stage %d-%d unlimited mode unlocked (killed %d elite)" % [c_ch, c_st, game_manager.elites_killed_this_run])
			var chapter := StageData.get_chapter(c_ch)
			if chapter != null and c_st < chapter.stages.size() + 1:
				GameState.unlock_stage(c_ch, c_st + 1)

func _build_settlement_scene(reason: String, coin_gained: int, minerals_gained: int, kills: int, level: int, loot: Array = []) -> Node:
	var scene_res = load("res://scenes/SettlementScene.tscn")
	if not scene_res:
		push_error("[GameScene] failed to load SettlementScene.tscn")
		return null

	var settlement = scene_res.instantiate()
	settlement.process_mode = Node.PROCESS_MODE_ALWAYS

	var result_labels = {
		"dead": ["任务失败", "舰船损毁，损失50%%收益"],
		"timeout": ["任务失败", "时间耗尽，损失50%%收益"],
		"retreat": ["任务完成", "撤离成功，100%%收益"],
		"self_destruct": ["任务中止", "自毁退出，无收益"],
		"s6_victory": ["任务完成", "全部BOSS已击杀，解锁下一章节！"],
	}
	var rl = result_labels.get(reason, ["任务完成", ""])

	var result_label = settlement.get_node_or_null("Panel/VBox/ResultLabel")
	if result_label:
		result_label.text = rl[0]
	var result_desc = settlement.get_node_or_null("Panel/VBox/ResultDesc")
	if result_desc:
		result_desc.text = rl[1]

	var kills_label = settlement.get_node_or_null("Panel/VBox/StatsGrid/KillsValue")
	if kills_label:
		kills_label.text = "%d" % kills
	var level_label = settlement.get_node_or_null("Panel/VBox/StatsGrid/LevelValue")
	if level_label:
		level_label.text = "%d" % level
	var coin_label = settlement.get_node_or_null("Panel/VBox/StatsGrid/CoinValue")
	if coin_label:
		coin_label.text = "%d" % GameState.star_coin
	var minerals_label = settlement.get_node_or_null("Panel/VBox/StatsGrid/MineralsValue")
	if minerals_label:
		minerals_label.text = "%d" % (GameState.minerals_low + GameState.minerals_mid + GameState.minerals_high)
	var earned_coin_label = settlement.get_node_or_null("Panel/VBox/StatsGrid/EarnedHBox/EarnedCoinValue")
	if earned_coin_label:
		earned_coin_label.text = "+%d" % coin_gained
	var earned_minerals_label = settlement.get_node_or_null("Panel/VBox/StatsGrid/EarnedMineralsValue")
	if earned_minerals_label:
		earned_minerals_label.text = "+%d" % minerals_gained

	if settlement.has_method("set_settlement_data"):
		settlement.set_settlement_data(reason, kills, level, coin_gained, minerals_gained, loot)

	var ship_status_label = settlement.get_node_or_null("Panel/VBox/ShipStatusLabel")
	if ship_status_label:
		if GameState.ship_damaged:
			ship_status_label.text = "舰船损坏 - 维修费: %d 星币" % GameState.get_repair_cost()
			ship_status_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
		else:
			ship_status_label.text = "舰船状态: 良好"
			ship_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1))

	var retry_btn = settlement.get_node_or_null("Panel/VBox/ButtonsHBox/RetryBtn")
	if retry_btn:
		if reason == "self_destruct":
			retry_btn.text = "重新开始"
			retry_btn.disabled = false
		elif GameState.ship_damaged and GameState.star_coin < GameState.get_repair_cost():
			retry_btn.text = "星币不足"
			retry_btn.disabled = true
		else:
			retry_btn.text = "重新开始"
			retry_btn.disabled = GameState.ship_damaged

	return settlement

func _connect_settlement_buttons(settlement: Node) -> void:
	var retry_btn = settlement.get_node_or_null("Panel/VBox/ButtonsHBox/RetryBtn")
	if retry_btn:
		retry_btn.pressed.connect(_on_settlement_retry)
	var base_btn = settlement.get_node_or_null("Panel/VBox/ButtonsHBox/BaseBtn")
	if base_btn:
		base_btn.pressed.connect(_on_settlement_base)
	var menu_btn = settlement.get_node_or_null("Panel/VBox/ButtonsHBox/MenuBtn")
	if menu_btn:
		menu_btn.pressed.connect(_on_settlement_menu)

func _on_settlement_retry() -> void:
	SoundManager.play_sfx("button_click")
	print("[GameScene] settlement retry")
	if GameState.ship_damaged:
		if GameState.star_coin >= GameState.get_repair_cost():
			GameState.repair_ship()
	(Engine.get_main_loop() as SceneTree).change_scene_to_file("res://scenes/GameScene.tscn")

func _on_settlement_base() -> void:
	SoundManager.play_sfx("button_click")
	print("[GameScene] settlement base")
	(Engine.get_main_loop() as SceneTree).change_scene_to_file("res://scenes/BaseScene.tscn")

func _on_settlement_menu() -> void:
	SoundManager.play_sfx("button_click")
	print("[GameScene] settlement menu")
	(Engine.get_main_loop() as SceneTree).change_scene_to_file("res://scenes/MainMenu.tscn")

func _game_over_to_base() -> void:
	await get_tree().create_timer(0.1).timeout
	(Engine.get_main_loop() as SceneTree).change_scene_to_file("res://scenes/BaseScene.tscn")

func trigger_screen_shake(intensity: float = 8.0, duration: float = 0.2) -> void:
	shake_intensity = intensity
	shake_duration = duration
	shake_time = 0.0

func _update_screen_shake(delta: float) -> void:
	if shake_duration > 0:
		shake_time += delta
		if shake_time >= shake_duration:
			shake_duration = 0
			shake_time = 0
			$PlayerRoot.position = original_offset
			return

		var shake = shake_intensity * (1.0 - shake_time / shake_duration)
		var offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
		$PlayerRoot.position = offset

var newbie_guide: CanvasLayer = null

func _maybe_start_guide() -> void:
	if not GameState.first_run:
		return
	if not ResourceLoader.exists("res://scripts/newbie_guide.gd"):
		return
	var guide_script = load("res://scripts/newbie_guide.gd")
	if not guide_script:
		return
	newbie_guide = CanvasLayer.new()
	newbie_guide.script = guide_script
	newbie_guide.layer = 200
	add_child(newbie_guide)
	newbie_guide.visible = false
	await get_tree().process_frame
	if newbie_guide and newbie_guide.has_method("start_guide"):
		newbie_guide.start_guide()
		_setup_guide_signals()
	print("[GameScene] NewbieGuide started")

func _setup_guide_signals() -> void:
	if not newbie_guide:
		return
	newbie_guide.guide_completed.connect(_on_guide_completed)

func _on_guide_completed() -> void:
	print("[GameScene] Guide completed")
	GameState.first_run = false

func _notify_guide_pause() -> void:
	if newbie_guide and newbie_guide.has_method("notify_pause_opened"):
		newbie_guide.notify_pause_opened()

func _notify_guide_level_up() -> void:
	if newbie_guide and newbie_guide.has_method("notify_level_up"):
		newbie_guide.notify_level_up()
