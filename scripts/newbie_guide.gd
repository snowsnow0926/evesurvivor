extends CanvasLayer

signal guide_completed
signal step_changed(step_index: int)

const TOTAL_STEPS: int = 6

var current_step: int = 0
var is_guide_active: bool = false
var overlay: ColorRect
var steps: Array = []

var step_labels: Array = []
var arrow: Label
var skip_btn: Button

func _ready() -> void:
	visible = false
	_setup_steps()
	_setup_overlay()
	_setup_arrow()
	_setup_skip_button()

func _setup_steps() -> void:
	steps = [
		{
			"text": "WASD 移动你的舰船",
			"position": "center_bottom",
		},
		{
			"text": "敌人会自动出现，武器会自动射击",
			"position": "center_top",
		},
		{
			"text": "靠近蓝色发光球体获取经验值",
			"position": "left_center",
		},
		{
			"text": "经验条满了之后选择升级来强化你的舰船",
			"position": "center",
		},
		{
			"text": "按 ESC 暂停，可以选择撤离结算",
			"position": "top_right",
		},
		{
			"text": "活下去，攒钱，换更大的船！",
			"position": "center",
		},
	]

func _setup_overlay() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.mouse_default_cursor_shape = Control.CURSOR_ARROW
	overlay.gui_input.connect(_on_overlay_input)
	add_child(overlay)
	move_child(overlay, 0)

func _setup_skip_button() -> void:
	skip_btn = Button.new()
	skip_btn.text = "跳过引导"
	skip_btn.custom_minimum_size = Vector2(120, 44)
	skip_btn.pressed.connect(_skip_guide)
	add_child(skip_btn)

func _update_skip_button_position() -> void:
	if not is_instance_valid(skip_btn):
		return
	var screen_size = get_viewport().get_visible_rect().size
	skip_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_btn.offset_left = -130
	skip_btn.offset_top = 10
	skip_btn.offset_right = -10
	skip_btn.offset_bottom = 54

func _setup_arrow() -> void:
	arrow = Label.new()
	arrow.text = ">>>"
	arrow.add_theme_font_size_override("font_size", 32)
	arrow.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(arrow)

func start_guide() -> void:
	if GameState == null:
		return
	if not GameState.get("first_run"):
		return

	is_guide_active = true
	current_step = 0
	visible = true
	_refresh_step()
	print("[NewbieGuide] Guide started at step 0")

func stop_guide() -> void:
	is_guide_active = false
	visible = false
	queue_step_labels_clear()
	queue_free()

func _refresh_step() -> void:
	queue_step_labels_clear()

	if current_step < 0 or current_step >= steps.size():
		_complete_guide()
		return

	overlay.color.a = 0.0
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.6, 0.3)

	var step = steps[current_step]
	_show_step_label(current_step, step["text"], step["position"])
	_show_step_arrow(current_step, step["position"])
	_update_skip_button_position()

	step_changed.emit(current_step)

func queue_step_labels_clear() -> void:
	for lbl in step_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	step_labels.clear()
	if is_instance_valid(arrow):
		arrow.visible = false

func _show_step_label(index: int, text: String, pos_key: String) -> void:
	var screen_size = get_viewport().get_visible_rect().size
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set("theme_override_colors/font_outline_color", Color(0.0, 0.5, 1.0))
	label.set("theme_override_constants/outline_size", 3)
	add_child(label)
	step_labels.append(label)

	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.1, 0.3, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_child(bg)
	bg.set("layout_mode", 1)
	bg.set("anchor_right", 1)
	bg.set("anchor_bottom", 1)
	bg.set("offset_left", -15)
	bg.set("offset_top", -8)
	bg.set("offset_right", 15)
	bg.set("offset_bottom", 8)

	var pos = _get_label_position(pos_key, screen_size)
	label.position = pos

	_arrow_to_label(pos_key, screen_size, label)

func _get_label_position(pos_key: String, screen_size: Vector2) -> Vector2:
	match pos_key:
		"center":
			return Vector2(screen_size.x / 2 - 200, screen_size.y / 2 - 50)
		"center_top":
			return Vector2(screen_size.x / 2 - 200, 80)
		"center_bottom":
			return Vector2(screen_size.x / 2 - 200, screen_size.y - 150)
		"left_center":
			return Vector2(40, screen_size.y / 2 - 50)
		"top_right":
			return Vector2(screen_size.x - 350, 80)
		"bottom_right":
			return Vector2(screen_size.x - 350, screen_size.y - 150)
	return Vector2(screen_size.x / 2 - 200, screen_size.y / 2 - 50)

func _show_step_arrow(index: int, pos_key: String) -> void:
	if not is_instance_valid(arrow):
		return
	arrow.visible = false

func _arrow_to_label(pos_key: String, screen_size: Vector2, label: Label) -> void:
	if not is_instance_valid(arrow):
		return
	arrow.visible = true

	match pos_key:
		"center_top":
			arrow.position = Vector2(screen_size.x / 2 - 10, 40)
		"center_bottom":
			arrow.position = Vector2(screen_size.x / 2 - 10, screen_size.y - 110)
		"left_center":
			arrow.position = Vector2(10, screen_size.y / 2 - 10)
		"top_right":
			arrow.position = Vector2(screen_size.x - 30, 40)
		_:
			arrow.visible = false
			return

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(arrow, "position:y", arrow.position.y - 8, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(arrow, "modulate:a", 0.3, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_property(arrow, "position:y", arrow.position.y + 8, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_property(arrow, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_callback(_arrow_ping_done)

func _arrow_ping_done() -> void:
	if is_guide_active and is_instance_valid(arrow) and arrow.visible:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(arrow, "position:y", arrow.position.y - 8, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(arrow, "modulate:a", 0.3, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween.chain().tween_property(arrow, "position:y", arrow.position.y + 8, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween.chain().tween_property(arrow, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween.chain().tween_callback(_arrow_ping_done)

func _on_overlay_input(event: InputEvent) -> void:
	if not is_guide_active:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_advance_step()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_advance_step()
	elif event is InputEventKey:
		if event.pressed:
			if event.is_action("ui_accept") or event.is_action_pressed("space"):
				_advance_step()
			elif event.is_action_pressed("ui_cancel"):
				_skip_guide()

func _advance_step() -> void:
	current_step += 1
	if current_step >= TOTAL_STEPS:
		_complete_guide()
	else:
		_refresh_step()

func _skip_guide() -> void:
	print("[NewbieGuide] Guide skipped at step ", current_step)
	_complete_guide()

func _complete_guide() -> void:
	is_guide_active = false
	visible = false
	guide_completed.emit()
	print("[NewbieGuide] Guide completed")

func notify_enemy_killed() -> void:
	pass

func notify_level_up() -> void:
	pass

func notify_pause_opened() -> void:
	if is_guide_active and current_step == 4:
		_advance_step()
