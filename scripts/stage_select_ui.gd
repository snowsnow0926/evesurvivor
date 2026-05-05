extends Control

const StageData = preload("res://resources/stage_data.gd")

signal stage_selected(chapter_id: int, stage_id: int)

var current_chapter_id: int = 1
var current_chapter: StageData.ChapterInfo

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var stage_container: VBoxContainer = $Panel/VBox/ScrollContainer/StageContainer
@onready var back_btn: Button = $Panel/VBox/BackBtn

func _ready() -> void:
	_connect_buttons()
	_load_stages()

func _connect_buttons() -> void:
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)

func open(chapter_id: int) -> void:
	current_chapter_id = chapter_id
	current_chapter = StageData.get_chapter(chapter_id)
	if current_chapter == null:
		current_chapter = StageData.get_all_chapters()[0]
		current_chapter_id = current_chapter.id
	_update_title()
	_load_stages()
	visible = true

func _update_title() -> void:
	if title_label and current_chapter:
		title_label.text = current_chapter.name

func _load_stages() -> void:
	if not current_chapter or not stage_container:
		return
	for child in stage_container.get_children():
		child.queue_free()
	for stage: StageData.StageInfo in current_chapter.stages:
		var btn := _create_stage_button(stage)
		stage_container.add_child(btn)

func _create_stage_button(stage: StageData.StageInfo) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size.y = 70
	btn.set_meta("stage_id", stage.id)
	var is_unlocked = GameState.is_stage_unlocked(stage.id)
	var color := Color(0.1, 0.15, 0.25, 0.95) if stage.type == StageData.StageType.NORMAL else Color(0.3, 0.1, 0.3, 0.95)
	var hover_color := Color(0.2, 0.3, 0.4, 0.95)
	if not is_unlocked:
		btn.text = stage.name + " [未解锁]"
		btn.add_theme_color_override("normal", Color(0.1, 0.1, 0.1, 0.8))
		btn.add_theme_color_override("hover", Color(0.15, 0.15, 0.15, 0.8))
		btn.add_theme_color_override("pressed", Color(0.05, 0.05, 0.05, 0.8))
		btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		btn.disabled = true
	else:
		btn.text = stage.name
		btn.add_theme_color_override("normal", color)
		btn.add_theme_color_override("hover", hover_color)
		btn.add_theme_color_override("pressed", Color(0.05, 0.1, 0.15, 0.95))
		btn.pressed.connect(_on_stage_pressed.bind(stage.id))
	return btn

func _on_stage_pressed(stage_id: int) -> void:
	SoundManager.play_sfx("button_click")
	GameState.selected_stage_id = stage_id
	GameState.reset_for_new_run()
	queue_free()
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")

func _on_back_pressed() -> void:
	SoundManager.play_sfx("button_click")
	visible = false
	get_tree().change_scene_to_file("res://scenes/ChapterSelectUI.tscn")
