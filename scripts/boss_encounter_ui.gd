extends Control

## BOSS登场动画UI。在SpawnManager触发BOSS时调用 show_encounter()。
## 播放流程：遮罩淡入 → 立绘升起 → 名称显示 → 淡出 → emit finished

signal encounter_finished()

var _current_entry: BossEntry
var _is_playing: bool = false
var _warning_tween: Tween = null

@onready var _overlay: ColorRect = $Overlay
@onready var _warning_label: Label = $WarningLabel
@onready var _portrait_container: Control = $PortraitContainer
@onready var _portrait_sprite: Sprite2D = $PortraitContainer/PortraitSprite
@onready var _icon_sprite: Sprite2D = $PortraitContainer/IconSprite
@onready var _name_label: Label = $PortraitContainer/NameContainer/NameLabel
@onready var _subtitle_label: Label = $PortraitContainer/NameContainer/SubtitleLabel
@onready var _chapter_label: Label = $PortraitContainer/NameContainer/ChapterLabel

const ShipIconGenerator = preload("res://scripts/ship_icon_generator.gd")

func _ready() -> void:
	visible = false

func show_encounter(entry: BossEntry) -> void:
	if _is_playing:
		return
	_is_playing = true
	_current_entry = entry
	visible = true
	_reset_all_nodes()
	_apply_boss_data(entry)
	_play_intro_animation()


func _reset_all_nodes() -> void:
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_portrait_container.position.y = 700.0
	_portrait_sprite.visible = false
	_icon_sprite.visible = false
	_name_label.text = ""
	_name_label.modulate.a = 0.0
	_subtitle_label.text = ""
	_subtitle_label.modulate.a = 0.0
	_chapter_label.text = ""
	_chapter_label.modulate.a = 0.0
	_warning_label.visible = false
	if _warning_tween:
		_warning_tween.kill()
		_warning_tween = null


func _apply_boss_data(entry: BossEntry) -> void:
	_name_label.text = entry.name_zh
	_subtitle_label.text = entry.name_en
	_chapter_label.text = "第%d章 · %s" % [entry.chapter, _get_chapter_name(entry.chapter)]
	_warning_label.text = "警告：BOSS来袭"

	if entry.has_portrait():
		_portrait_sprite.visible = true
		_icon_sprite.visible = false
		var tex = load(entry.portrait_path)
		if tex:
			_portrait_sprite.texture = tex
	else:
		_portrait_sprite.visible = false
		_icon_sprite.visible = true
		var icon_entry = ShipIconGenerator.get_entry(
			ShipIconGenerator.Category.ENEMY,
			entry.icon_id
		)
		if icon_entry:
			_icon_sprite.texture = icon_entry.get_texture(entry.base_tint)


func _get_chapter_name(chapter_id: int) -> String:
	match chapter_id:
		1: return "黑渊之地"
		2: return "婓德之境"
		3: return "德克廉深渊"
		4: return "特布特前线"
		5: return "维纳尔混乱之地"
		6: return "血脉死域"
	return "未知区域"


func _play_intro_animation() -> void:
	SoundManager.play_sfx("boss_appear")
	SoundManager.play_music("battle_boss")

	_warning_flash_loop()

	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_property(_overlay, "color:a", 0.78, 0.3)
	t.tween_property(_portrait_container, "position:y", 0.0, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(1.2).timeout

	t = create_tween()
	t.set_parallel(true)
	t.tween_property(_name_label, "modulate:a", 1.0, 0.4)
	t.tween_property(_subtitle_label, "modulate:a", 1.0, 0.4)
	t.tween_property(_chapter_label, "modulate:a", 1.0, 0.4)

	await get_tree().create_timer(1.3).timeout

	t = create_tween()
	t.set_parallel(true)
	t.tween_property(_overlay, "color:a", 0.0, 0.4)
	t.tween_callback(_on_animation_finished)


func _warning_flash_loop() -> void:
	_warning_label.visible = true
	_warning_label.modulate.a = 1.0
	_warning_tween = create_tween()
	_warning_tween.set_loops()
	_warning_tween.tween_property(_warning_label, "modulate", Color(1.0, 0.2, 0.2, 1.0), 0.4)
	_warning_tween.tween_property(_warning_label, "modulate", Color(1.0, 0.6, 0.6, 1.0), 0.4)


func _on_animation_finished() -> void:
	_is_playing = false
	_current_entry = null
	visible = false
	modulate = Color.WHITE
	if _warning_tween:
		_warning_tween.kill()
		_warning_tween = null
	encounter_finished.emit()


func is_playing() -> bool:
	return _is_playing
