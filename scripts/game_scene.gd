extends Node2D

var game_manager: Node2D
var is_settlement_open: bool = false

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_time: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

const SETTLEMENT_SCENE_PATH := "res://scenes/SettlementScene.tscn"

func _ready() -> void:
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

func _input(event: InputEvent) -> void:
	pass

func _on_upgrade_requested() -> void:
	SoundManager.play_sfx("upgrade")
	_notify_guide_level_up()
	var upgrade_menu = $UIRoot/UpgradeMenu
	if upgrade_menu:
		upgrade_menu.open_upgrade_menu(game_manager.upgrade_pool, game_manager)

func _on_upgrade_selected(upgrade_id: String) -> void:
	SoundManager.play_sfx("upgrade_select")
	pass

func _on_retreat_requested() -> void:
	SoundManager.play_sfx("retreat_success")
	game_manager.on_stage_complete()
	_show_settlement_screen("retreat")

func _on_player_dead() -> void:
	_show_settlement_screen("dead")

func _on_self_destruct_requested() -> void:
	_game_over_to_base()

func _on_pause_toggled(is_paused: bool) -> void:
	if game_manager.is_game_over:
		return
	if is_paused:
		var pause_menu = $UIRoot/PauseMenu
		if not pause_menu.is_open:
			pause_menu.open_menu(game_manager)
	else:
		var pause_menu = $UIRoot/PauseMenu
		if pause_menu.is_open:
			pause_menu.close_menu()

func _on_game_ended(reason: String) -> void:
	_show_settlement_screen(reason)

func _show_settlement_screen(reason) -> void:
	if is_settlement_open:
		return
	is_settlement_open = true

	# 立即暂停游戏，防止任何节点继续运行
	get_tree().paused = true

	# 隐藏升级菜单，防止遮挡
	var upgrade_menu = $UIRoot/UpgradeMenu
	if upgrade_menu:
		upgrade_menu.visible = false
		upgrade_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 关闭暂停菜单，防止遮挡
	var pause_menu = $UIRoot/PauseMenu
	if pause_menu:
		pause_menu.visible = false
		pause_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 必须在 on_run_ended() 修改 GameState 之前读取，进入前的星币/矿物数值才正确
	var pre_loot_coin = GameState.star_coin
	var pre_loot_min_low = GameState.minerals_low
	var pre_loot_min_mid = GameState.minerals_mid
	var pre_loot_min_high = GameState.minerals_high
	var pre_loot_loot = game_manager.get_session_loot().duplicate(true)

	var coin_gained = game_manager.session_star_coin
	var min_low = game_manager.session_minerals_low
	var min_mid = game_manager.session_minerals_mid
	var min_high = game_manager.session_minerals_high
	var kills = game_manager.total_kills
	var level = game_manager.player_level
	var elapsed_time = game_manager.timer_elapsed if game_manager.timer_counting_up else (game_manager.FIRST_RUN_DURATION - game_manager.time_remaining)

	match reason:
		"dead":
			GameState.last_run_reason = "dead"
			GameState.on_run_ended(kills, level, coin_gained, min_low, min_mid, min_high, true, reason)
		"timeout":
			GameState.last_run_reason = "timeout"
			GameState.on_run_ended(kills, level, coin_gained, min_low, min_mid, min_high, false, reason)
			if not GameState.is_stage_first_complete(GameState.selected_stage_id):
				GameState.stage_first_complete.append(GameState.selected_stage_id)
		"retreat":
			GameState.last_run_reason = "retreat"
			GameState.on_run_ended(kills, level, coin_gained, min_low, min_mid, min_high, false, reason)
		"self_destruct":
			GameState.last_run_reason = "self_destruct"
			GameState.on_run_ended(kills, level, coin_gained, min_low, min_mid, min_high, false, reason)
		_:
			GameState.last_run_reason = reason
			GameState.on_run_ended(kills, level, coin_gained, min_low, min_mid, min_high, false, reason)
	game_manager.grant_loot_to_player()

	# 切换结算音乐
	SoundManager.play_music("settlement")

	# 动态加载结算界面（绕过脚本依赖）
	var settlement_packed = load(SETTLEMENT_SCENE_PATH)
	if not settlement_packed:
		push_error("[GameScene] Failed to load SettlementScene: " + SETTLEMENT_SCENE_PATH)
		return
	var settlement = settlement_packed.instantiate()
	if not settlement:
		push_error("[GameScene] Failed to instantiate SettlementScene")
		return
	settlement.process_mode = Node.PROCESS_MODE_ALWAYS

	# 直接操作节点设置结算数据（绕过 settlement_scene.gd 脚本依赖）
	_settlement_set_data(settlement, reason, kills, level,
		coin_gained, min_low, min_mid, min_high,
		pre_loot_coin, pre_loot_min_low, pre_loot_min_mid, pre_loot_min_high,
		pre_loot_loot)

	$UIRoot.add_child(settlement)
	settlement.visible = true

	# 手动连接按钮信号
	_connect_settlement_buttons(settlement, reason)

func _settlement_set_data(s: Control, reason: String, kills: int, level: int,
		p_coin: int, p_low: int, p_mid: int, p_high: int,
		p_pre_coin: int, p_pre_low: int, p_pre_mid: int, p_pre_high: int,
		loot: Array) -> void:
	# 设置标题
	var title = s.get_node_or_null("Panel/VBox/TitleLabel")
	if title:
		match reason:
			"dead": title.text = "任务失败"
			"timeout": title.text = "时间到！"
			"self_destruct": title.text = "任务中止"
			_: title.text = "撤退结算"

	# 格式化数字
	var fmt := func(n: int) -> String:
		if n >= 1_000_000:
			var mil := n / 1_000_000
			var rem := n % 1_000_000
			if rem == 0: return "%dM" % mil
			return "%d,%03d,%03d" % [mil, rem / 1000, rem % 1000]
		elif n >= 1000:
			var k := n / 1000
			var rem := n % 1000
			if rem == 0: return "%dk" % k
			return "%d,%03d" % [k, rem]
		return "%d" % n

	# 星币
	if (s.get_node_or_null("Panel/VBox/IncomeVBox/CoinRow/CoinPreValue")) as Label:
		(s.get_node("Panel/VBox/IncomeVBox/CoinRow/CoinPreValue") as Label).text = fmt.call(p_pre_coin)
	if (s.get_node_or_null("Panel/VBox/IncomeVBox/CoinRow/CoinEarnedValue")) as Label:
		(s.get_node("Panel/VBox/IncomeVBox/CoinRow/CoinEarnedValue") as Label).text = fmt.call(p_coin)
	if (s.get_node_or_null("Panel/VBox/IncomeVBox/CoinRow/CoinTotalValue")) as Label:
		(s.get_node("Panel/VBox/IncomeVBox/CoinRow/CoinTotalValue") as Label).text = fmt.call(p_pre_coin + p_coin)

	# 矿物低
	if (s.get_node_or_null("Panel/VBox/IncomeVBox/MinLowRow/MinLowPreValue")) as Label:
		(s.get_node("Panel/VBox/IncomeVBox/MinLowRow/MinLowPreValue") as Label).text = fmt.call(p_pre_low)
	if (s.get_node_or_null("Panel/VBox/IncomeVBox/MinLowRow/MinLowEarnedValue")) as Label:
		(s.get_node("Panel/VBox/IncomeVBox/MinLowRow/MinLowEarnedValue") as Label).text = fmt.call(p_low)
	if (s.get_node_or_null("Panel/VBox/IncomeVBox/MinLowRow/MinLowTotalValue")) as Label:
		(s.get_node("Panel/VBox/IncomeVBox/MinLowRow/MinLowTotalValue") as Label).text = fmt.call(p_pre_low + p_low)

	# 矿物中
	if (s.get_node_or_null("Panel/VBox/IncomeVBox/MinMidRow/MinMidPreValue")) as Label:
		(s.get_node("Panel/VBox/IncomeVBox/MinMidRow/MinMidPreValue") as Label).text = fmt.call(p_pre_mid)
	if (s.get_node_or_null("Panel/VBox/IncomeVBox/MinMidRow/MinMidEarnedValue")) as Label:
		(s.get_node("Panel/VBox/IncomeVBox/MinMidRow/MinMidEarnedValue") as Label).text = fmt.call(p_mid)
	if (s.get_node_or_null("Panel/VBox/IncomeVBox/MinMidRow/MinMidTotalValue")) as Label:
		(s.get_node("Panel/VBox/IncomeVBox/MinMidRow/MinMidTotalValue") as Label).text = fmt.call(p_pre_mid + p_mid)

	# 矿物高
	if (s.get_node_or_null("Panel/VBox/IncomeVBox/MinHighRow/MinHighPreValue")) as Label:
		(s.get_node("Panel/VBox/IncomeVBox/MinHighRow/MinHighPreValue") as Label).text = fmt.call(p_pre_high)
	if (s.get_node_or_null("Panel/VBox/IncomeVBox/MinHighRow/MinHighEarnedValue")) as Label:
		(s.get_node("Panel/VBox/IncomeVBox/MinHighRow/MinHighEarnedValue") as Label).text = fmt.call(p_high)
	if (s.get_node_or_null("Panel/VBox/IncomeVBox/MinHighRow/MinHighTotalValue")) as Label:
		(s.get_node("Panel/VBox/IncomeVBox/MinHighRow/MinHighTotalValue") as Label).text = fmt.call(p_pre_high + p_high)

	# 掉落物品
	var loot_scroll = s.get_node_or_null("Panel/VBox/LootScroll")
	var loot_container = s.get_node_or_null("Panel/VBox/LootScroll/LootContainer")
	var empty_label = s.get_node_or_null("Panel/VBox/LootScroll/LootContainer/EmptyLootLabel")
	if empty_label:
		empty_label.visible = loot.size() == 0
	if loot.size() > 0 and loot_container:
		for child in loot_container.get_children():
			if child.name != "EmptyLootLabel":
				child.queue_free()
		const EqData = preload("res://resources/equipment_data.gd")
		const WpnData = preload("res://resources/weapon_data.gd")
		var shop_map := {
			0: 4, 1: 8, 2: 12, 3: 16, 4: 5, 5: 9, 6: 13, 7: 17,
			8: 6, 9: 10, 10: 14, 11: 18, 12: 7, 13: 11, 14: 15, 15: 19
		}
		for item: Dictionary in loot:
			var row := HBoxContainer.new()
			var t := "武器" if item.get("type") == "weapon" else "防具"
			var name_str := "?"
			var q_color := Color.WHITE
			if item.get("type") == "weapon":
				var wid: int = item.get("weapon_id", 0)
				if wid == 0:
					wid = shop_map.get(item.get("shop_item_id", 0), 0)
				var wd = WpnData.get_weapon(wid)
				name_str = wd.display_name if wd else "?"
				q_color = EqData.get_quality_color(item.get("quality", 0))
			else:
				var aid: int = item.get("armor_id", 0)
				name_str = EqData.get_armor_name(aid) if aid >= 0 else "?"
				q_color = EqData.get_quality_color(item.get("quality", 0))
			var lbl := Label.new()
			lbl.text = "- %s [%s]" % [t, name_str]
			lbl.add_theme_color_override("font_color", q_color)
			row.add_child(lbl)
			loot_container.add_child(row)

func _connect_settlement_buttons(settlement: Control, reason: String) -> void:
	# 返回基地按钮
	var base_btn = settlement.get_node_or_null("Panel/VBox/ButtonsHBox/BaseBtn")
	if base_btn:
		base_btn.pressed.connect(_on_settlement_base)

	# 重新开始按钮
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
		retry_btn.pressed.connect(_on_settlement_retry)

	# 主菜单按钮
	var menu_btn = settlement.get_node_or_null("Panel/VBox/ButtonsHBox/MenuBtn")
	if menu_btn:
		menu_btn.pressed.connect(_on_settlement_menu)

func _on_settlement_retry() -> void:
	SoundManager.play_sfx("button_click")
	if GameState.ship_damaged:
		if GameState.star_coin >= GameState.get_repair_cost():
			GameState.repair_ship()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")

func _on_settlement_base() -> void:
	SoundManager.play_sfx("button_click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/BaseScene.tscn")

func _on_settlement_menu() -> void:
	SoundManager.play_sfx("button_click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _game_over_to_base() -> void:
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/BaseScene.tscn")

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
