extends Control

var settlement_reason: String = ""
var session_kills: int = 0
var session_coin: int = 0
var session_minerals: int = 0
var session_level: int = 1
var earned_coin: int = 0
var earned_minerals: int = 0

@onready var result_label: Label = $Panel/VBox/ResultLabel
@onready var result_desc: Label = $Panel/VBox/ResultDesc
@onready var kills_label: Label = $Panel/VBox/StatsGrid/KillsValue
@onready var level_label: Label = $Panel/VBox/StatsGrid/LevelValue
@onready var coin_label: Label = $Panel/VBox/StatsGrid/CoinValue
@onready var minerals_label: Label = $Panel/VBox/StatsGrid/MineralsValue
@onready var earned_coin_label: Label = $Panel/VBox/StatsGrid/EarnedCoinValue
@onready var earned_minerals_label: Label = $Panel/VBox/StatsGrid/EarnedMineralsValue
@onready var ship_status_label: Label = $Panel/VBox/ShipStatusLabel
@onready var retry_btn: Button = $Panel/VBox/ButtonsHBox/RetryBtn
@onready var base_btn: Button = $Panel/VBox/ButtonsHBox/BaseBtn
@onready var menu_btn: Button = $Panel/VBox/ButtonsHBox/MenuBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[SettlementScene] _ready called, process_mode=", process_mode)
	_connect_buttons()

func _connect_buttons() -> void:
	if retry_btn:
		print("[SettlementScene] retry_btn found, disabled=", retry_btn.disabled, " mouse_filter=", retry_btn.mouse_filter)
		retry_btn.pressed.connect(_on_retry_pressed)
	if base_btn:
		print("[SettlementScene] base_btn found, disabled=", base_btn.disabled, " mouse_filter=", base_btn.mouse_filter)
		base_btn.pressed.connect(_on_base_pressed)
	if menu_btn:
		print("[SettlementScene] menu_btn found, disabled=", menu_btn.disabled, " mouse_filter=", menu_btn.mouse_filter)
		menu_btn.pressed.connect(_on_menu_pressed)

func set_settlement_data(reason: String, kills: int, level: int, coin: int, minerals: int) -> void:
	print("[SettlementScene] set_settlement_data: reason=", reason, " kills=", kills, " level=", level, " coin=", coin, " minerals=", minerals)
	settlement_reason = reason
	session_kills = kills
	session_level = level
	session_coin = GameState.star_coin
	session_minerals = GameState.minerals_low + GameState.minerals_mid + GameState.minerals_high

	earned_coin = coin
	earned_minerals = minerals

	GameState.last_run_reason = reason

	_update_display()

func _gui_input(event: InputEvent) -> void:
	print("[SettlementScene] _gui_input: ", event.as_text())

func _update_display() -> void:
	if result_label:
		match settlement_reason:
			"dead":
				result_label.text = "任务失败"
			"timeout":
				result_label.text = "时间到！"
			"retreat":
				result_label.text = "任务完成"
			"self_destruct":
				result_label.text = "任务中止"
			_:
				result_label.text = "任务完成"

	if result_desc:
		match settlement_reason:
			"dead":
				result_desc.text = "舰船损毁，损失50%%收益"
			"timeout":
				result_desc.text = "时间到！100%%收益"
			"retreat":
				result_desc.text = "撤离成功，100%%收益"
			"self_destruct":
				result_desc.text = "自毁退出，无收益"
			_:
				result_desc.text = ""

	if kills_label:
		kills_label.text = "%d" % session_kills
	if level_label:
		level_label.text = "%d" % session_level
	if coin_label:
		coin_label.text = "%d" % session_coin
	if minerals_label:
		minerals_label.text = "%d" % session_minerals
	if earned_coin_label:
		earned_coin_label.text = "+%d" % earned_coin
	if earned_minerals_label:
		earned_minerals_label.text = "+%d" % earned_minerals

	if ship_status_label:
		if GameState.ship_damaged:
			ship_status_label.text = "舰船损坏 - 维修费: %d 星币" % GameState.get_repair_cost()
			ship_status_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
		else:
			ship_status_label.text = "舰船状态: 良好"
			ship_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1))

	if retry_btn:
		if settlement_reason == "self_destruct":
			retry_btn.text = "重新开始"
			retry_btn.disabled = false
		elif GameState.ship_damaged and GameState.star_coin < GameState.get_repair_cost():
			retry_btn.text = "星币不足"
			retry_btn.disabled = true
		else:
			retry_btn.text = "重新开始"
			retry_btn.disabled = GameState.ship_damaged

func set_reason(reason: String) -> void:
	settlement_reason = reason
	_update_display()

func _on_retry_pressed() -> void:
	print("[SettlementScene] retry pressed")
	if GameState.ship_damaged:
		if GameState.star_coin >= GameState.get_repair_cost():
			GameState.repair_ship()
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")

func _on_menu_pressed() -> void:
	print("[SettlementScene] menu pressed")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_base_pressed() -> void:
	print("[SettlementScene] base pressed")
	get_tree().change_scene_to_file("res://scenes/BaseScene.tscn")
