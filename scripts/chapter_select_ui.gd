extends Control

const StageData = preload("res://resources/stage_data.gd")

@onready var GameState: Node = get_node("/root/GameState")

signal chapter_selected(chapter_id: int)

var stage_select_ui: Control
var stage_select_scene: PackedScene

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var back_btn: Button = $Panel/VBox/BackBtn

const CARD_PATHS: Array[String] = [
	"Panel/VBox/ScrollContainer/ChapterContainer/Card1",
	"Panel/VBox/ScrollContainer/ChapterContainer/Card2",
	"Panel/VBox/ScrollContainer/ChapterContainer/Card3",
	"Panel/VBox/ScrollContainer/ChapterContainer/Card4",
	"Panel/VBox/ScrollContainer/ChapterContainer/Card5",
	"Panel/VBox/ScrollContainer/ChapterContainer/Card6",
]

func _ready() -> void:
	stage_select_scene = load("res://scenes/StageSelectUI.tscn")
	_connect_buttons()
	_load_chapters()

func _connect_buttons() -> void:
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)

func _load_chapters() -> void:
	var chapters := StageData.get_all_chapters()
	for i in range(min(chapters.size(), CARD_PATHS.size())):
		var chapter: StageData.ChapterInfo = chapters[i]
		var card_path := CARD_PATHS[i]
		var card: Panel = get_node(card_path)
		var is_unlocked: bool = GameState.is_chapter_unlocked(chapter.id)
		_configure_card(card, chapter, is_unlocked)

func _configure_card(card: Panel, chapter: StageData.ChapterInfo, is_unlocked: bool) -> void:
	var name_label: Label = card.get_node_or_null("VBox/NameLabel")
	var desc_label: Label = card.get_node_or_null("VBox/DescLabel")
	var click_btn: Button = card.get_node_or_null("ClickBtn")
	var card_img: TextureRect = card.get_node_or_null("CardImage")

	if card_img:
		if not is_unlocked:
			var gray_mat := ShaderMaterial.new()
			gray_mat.shader = load("res://shaders/grayscale.gdshader")
			card_img.material = gray_mat

	if name_label:
		name_label.text = chapter.name + (" [锁定]" if not is_unlocked else "")
		name_label.add_theme_font_size_override("font_size", 24)
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6) if not is_unlocked else Color(0.9, 0.9, 1.0))

	if desc_label:
		desc_label.text = chapter.description
		desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))

	if click_btn:
		if is_unlocked:
			if not click_btn.pressed.is_connected(_on_chapter_pressed):
				click_btn.pressed.connect(_on_chapter_pressed.bind(chapter.id))
		else:
			click_btn.add_theme_color_override("normal", Color(0.05, 0.05, 0.1, 0.5))
			click_btn.add_theme_color_override("hover", Color(0.05, 0.05, 0.1, 0.5))

	card.add_theme_stylebox_override("panel", _make_chapter_style(is_unlocked))

func _make_chapter_style(is_unlocked: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.22, 0.9) if is_unlocked else Color(0.04, 0.04, 0.08, 0.7)
	style.border_color = Color(0.2, 0.3, 0.5, 0.6) if is_unlocked else Color(0.1, 0.1, 0.2, 0.3)
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
	var stage_ui: Node = stage_select_scene.instantiate()
	var root := get_tree().root
	root.add_child(stage_ui)
	if stage_ui.has_method("open"):
		stage_ui.open(chapter_id)
	if stage_ui.has_signal("stage_selected"):
		stage_ui.stage_selected.connect(_on_stage_selected)

func _on_stage_selected(chapter_id: int, stage_id: int) -> void:
	chapter_selected.emit(chapter_id, stage_id)

func _on_back_pressed() -> void:
	SoundManager.play_sfx("button_click")
	get_tree().change_scene_to_file("res://scenes/BaseScene.tscn")
