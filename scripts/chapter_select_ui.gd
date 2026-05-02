extends Control

const StageData = preload("res://resources/stage_data.gd")

signal chapter_selected(chapter_id: int)

var stage_select_ui: Control
var stage_select_scene: PackedScene

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var chapter_container: VBoxContainer = $Panel/VBox/ScrollContainer/ChapterContainer
@onready var back_btn: Button = $Panel/VBox/BackBtn

func _ready() -> void:
	stage_select_scene = load("res://scenes/StageSelectUI.tscn")
	_connect_buttons()
	_load_chapters()

func _connect_buttons() -> void:
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)

func _load_chapters() -> void:
	var chapters := StageData.get_all_chapters()
	for chapter: StageData.ChapterInfo in chapters:
		var card := _create_chapter_card(chapter)
		chapter_container.add_child(card)

func _create_chapter_card(chapter: StageData.ChapterInfo) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size.y = 90
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 12.0
	vbox.offset_top = 8.0
	vbox.offset_right = -12.0
	vbox.offset_bottom = -8.0
	vbox.add_theme_constant_override("separation", 6)

	var name_label := Label.new()
	name_label.text = chapter.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = chapter.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(desc_label)

	var stage_count_label := Label.new()
	stage_count_label.text = "%d 个关卡" % chapter.stages.size()
	stage_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stage_count_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	vbox.add_child(stage_count_label)

	var btn := Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.text = ""
	btn.flat = true
	btn.pressed.connect(_on_chapter_pressed.bind(chapter.id))
	panel.add_child(btn)

	panel.add_theme_stylebox_override("panel", _make_chapter_style())
	return panel

func _make_chapter_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.22, 0.9)
	style.border_color = Color(0.2, 0.3, 0.5, 0.6)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

func _on_chapter_pressed(chapter_id: int) -> void:
	SoundManager.play_sfx("button_click")
	GameState.selected_chapter_id = chapter_id
	var tree := get_tree()
	tree.change_scene_to_file("res://scenes/StageSelectUI.tscn")
	await tree.process_frame
	var stage_ui: Node = tree.current_scene
	if stage_ui.has_method("open"):
		stage_ui.open(chapter_id)
	stage_ui.stage_selected.connect(_on_stage_selected)

func _on_stage_selected(chapter_id: int, stage_id: int) -> void:
	chapter_selected.emit(chapter_id, stage_id)

func _on_back_pressed() -> void:
	SoundManager.play_sfx("button_click")
	get_tree().change_scene_to_file("res://scenes/BaseScene.tscn")
