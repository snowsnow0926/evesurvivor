extends Control

@onready var race_list_container: VBoxContainer = $HSplit/LeftPanel/VBox/RaceList
@onready var confirm_btn: Button = $BottomBar/ConfirmBtn
@onready var back_btn: Button = $BottomBar/BackBtn

var selected_race: RaceData

func _ready():
	SoundManager.play_music("race_select")
	selected_race = RaceData.get_race(RaceData.RaceID.HUMAN)
	build_race_buttons()
	update_detail_panel(selected_race)
	if confirm_btn:
		confirm_btn.pressed.connect(_on_confirm_pressed)
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)

func build_race_buttons():
	for child in race_list_container.get_children():
		child.queue_free()

	var races = [
		RaceData.RaceID.HUMAN,
		RaceData.RaceID.ORC,
		RaceData.RaceID.PLANT,
		RaceData.RaceID.SILICON,
	]
	for race_id in races:
		var btn = Button.new()
		var race = RaceData.get_race(race_id)
		btn.text = race.display_name
		btn.pressed.connect(_on_race_selected.bind(race_id))
		race_list_container.add_child(btn)

func _on_race_selected(race_id: RaceData.RaceID):
	selected_race = RaceData.get_race(race_id)
	update_detail_panel(selected_race)

func update_detail_panel(race: RaceData):
	$HSplit/RightPanel/ScrollContainer/DetailVBox/RaceName.text = race.display_name
	$HSplit/RightPanel/ScrollContainer/DetailVBox/RaceDesc.text = race.description
	$HSplit/RightPanel/ScrollContainer/DetailVBox/AttrsSection/AttrHP.text = "HP: %.0f" % race.base_hp
	$HSplit/RightPanel/ScrollContainer/DetailVBox/AttrsSection/AttrShield.text = "护盾: %.0f" % race.shield_max
	$HSplit/RightPanel/ScrollContainer/DetailVBox/AttrsSection/AttrRegen.text = "回充: %.1f/s" % race.shield_regen
	$HSplit/RightPanel/ScrollContainer/DetailVBox/AttrsSection/AttrSpeed.text = "移速: %.0f" % race.move_speed
	$HSplit/RightPanel/ScrollContainer/DetailVBox/AttrsSection/AttrDodge.text = "闪避: %.0f%%" % (race.dodge_rate * 100)
	$HSplit/RightPanel/ScrollContainer/DetailVBox/AttrsSection/AttrCrit.text = "暴击: %.0f%%" % (race.crit_rate * 100)
	var weapon_name = "导弹"
	if "Cannon" in race.base_weapon_scene:
		weapon_name = "加农炮"
	elif "Railgun" in race.base_weapon_scene:
		weapon_name = "磁轨炮"
	elif "Laser" in race.base_weapon_scene:
		weapon_name = "激光炮"
	$HSplit/RightPanel/ScrollContainer/DetailVBox/DefaultWeapon.text = "默认武器: %s" % weapon_name
	var talent_text = ""
	for t in race.talents:
		talent_text += "[%s] %s\n" % [t["name"], t["desc"]]
	$HSplit/RightPanel/ScrollContainer/DetailVBox/Talents.text = talent_text if talent_text else "无种族天赋"

func _on_confirm_pressed():
	GameState.selected_race_id = selected_race.race_id
	GameState.on_run_started()
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
