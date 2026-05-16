extends CanvasLayer

signal guide_completed
signal step_changed(step_index: int)

enum Step {
	SHOP = 0,
	WAREHOUSE = 1,
	BATTLE_WASD = 2,
	BATTLE_XP = 3,
}

var current_step: int = 0
var is_guide_active: bool = false

var step_labels: Array = []
var skip_btn: Button

var _xp_collected_count: int = 0

func _ready() -> void:
	visible = false
	_setup_skip_button()

func _setup_skip_button() -> void:
	skip_btn = Button.new()
	skip_btn.text = "跳过引导"
	skip_btn.custom_minimum_size = Vector2(120, 44)
	skip_btn.pressed.connect(_skip_guide)
	add_child(skip_btn)

func _update_skip_button_position() -> void:
	if not is_instance_valid(skip_btn):
		return
	skip_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_btn.offset_left = -130
	skip_btn.offset_top = 10
	skip_btn.offset_right = -10
	skip_btn.offset_bottom = 54

func start_guide() -> void:
	if GameState == null:
		return
	if not GameState.get("guide_mode"):
		return
	is_guide_active = true
	current_step = 0
	visible = true
	print("[NewbieGuide] Guide started at step %d" % current_step)

func stop_guide() -> void:
	is_guide_active = false
	visible = false
	queue_step_labels_clear()

func _refresh_step() -> void:
	queue_step_labels_clear()
	var text := _get_step_text(current_step)
	_show_step_label(text)
	_update_skip_button_position()
	step_changed.emit(current_step)

func _get_step_text(step: int) -> String:
	match step:
		Step.SHOP:
			return "请选择种族并命名\n然后点击确认进入基地"
		Step.WAREHOUSE:
			return "点击武器商店购买武器\n再打开仓库安装武器到舰船上"
		Step.BATTLE_WASD:
			return "WASD 移动"
		Step.BATTLE_XP:
			return "靠近经验球获得经验"
	return ""

func _show_step_label(text: String) -> void:
	var screen_size = get_viewport().get_visible_rect().size
	var label = Label.new()
	label.text = text
	label.custom_minimum_size.x = 420
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set("theme_override_colors/font_outline_color", Color(0.0, 0.5, 1.0))
	label.set("theme_override_constants/outline_size", 3)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	step_labels.append(label)

	var pos = Vector2(screen_size.x / 2 - 210, screen_size.y / 2 + 60)
	label.position = pos

func queue_step_labels_clear() -> void:
	for lbl in step_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	step_labels.clear()

func next_step() -> void:
	if not is_guide_active:
		return
	if current_step == Step.SHOP:
		current_step = Step.WAREHOUSE
		_refresh_step()
		return
	_skip_guide()

func show_shop_guide() -> void:
	if not is_guide_active:
		return
	if current_step == Step.SHOP:
		next_step()

func show_warehouse_guide() -> void:
	if not is_guide_active:
		return
	if current_step == Step.WAREHOUSE:
		return
	current_step = Step.WAREHOUSE
	_refresh_step()

func show_battle_guide() -> void:
	if not is_guide_active:
		return
	current_step = Step.BATTLE_WASD
	_refresh_step()

func notify_xp_collected() -> void:
	if not is_guide_active:
		return
	if current_step == Step.BATTLE_WASD:
		current_step = Step.BATTLE_XP
		_refresh_step()
	elif current_step == Step.BATTLE_XP:
		_xp_collected_count += 1
		if _xp_collected_count >= 1:
			_complete_guide()

func _input(event: InputEvent) -> void:
	if not is_guide_active:
		return
	if event is InputEventKey:
		if event.pressed and event.is_action_pressed("ui_cancel"):
			_skip_guide()

func _skip_guide() -> void:
	print("[NewbieGuide] Guide skipped at step %d" % current_step)
	_complete_guide()

func _complete_guide() -> void:
	is_guide_active = false
	visible = false
	guide_completed.emit()
	print("[NewbieGuide] Guide completed")
