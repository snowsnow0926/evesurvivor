extends Control

const StageData = preload("res://resources/stage_data.gd")

@onready var GameState: Node = get_node("/root/GameState")

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
	for child in chapter_container.get_children():
		child.queue_free()
	var chapters := StageData.get_all_chapters()
	for chapter: StageData.ChapterInfo in chapters:
		var is_unlocked: bool = GameState.is_chapter_unlocked(chapter.id)
		var card := _create_chapter_card(chapter, is_unlocked)
		chapter_container.add_child(card)

func _create_chapter_card(chapter: StageData.ChapterInfo, is_unlocked: bool = true) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size.y = 90
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var img_path := "res://assets/base/menu/chapter_cards/chapter_%02d_card.png" % chapter.id
	var img_exists := FileAccess.file_exists(img_path)

	if img_exists:
		var tex_rect := TextureRect.new()
		tex_rect.name = "CardImage"
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var img := Image.new()
		img.load(img_path)
		if not is_unlocked:
			_desaturate_image(img)
		tex_rect.texture = ImageTexture.create_from_image(img)
		panel.add_child(tex_rect)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 12.0
	vbox.offset_top = 8.0
	vbox.offset_right = -12.0
	vbox.offset_bottom = -8.0
	vbox.add_theme_constant_override("separation", 6)

	var name_label := Label.new()
	name_label.text = chapter.name + (" [锁定]" if not is_unlocked else "")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6) if not is_unlocked else Color(0.9, 0.9, 1.0))
	vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = chapter.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(desc_label)

	var btn := Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.text = ""
	btn.flat = true
	if is_unlocked:
		btn.pressed.connect(_on_chapter_pressed.bind(chapter.id))
	else:
		btn.add_theme_color_override("normal", Color(0.05, 0.05, 0.1, 0.5))
		btn.add_theme_color_override("hover", Color(0.05, 0.05, 0.1, 0.5))
	panel.add_child(btn)

	panel.add_theme_stylebox_override("panel", _make_chapter_style(is_unlocked))
	return panel

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

func _desaturate_image(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			var gray := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			img.set_pixel(x, y, Color(gray * 0.5, gray * 0.5, gray * 0.5, c.a))
