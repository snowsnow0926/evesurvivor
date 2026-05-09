extends Control

const RaceData = preload("res://resources/race_data.gd")
const ShipData = preload("res://resources/ship_data.gd")
const WeaponData = preload("res://resources/weapon_data.gd")
const EquipmentData = preload("res://resources/equipment_data.gd")

signal speed_changed(speed: float)

const UPGRADE_NAME_MAP: Dictionary = {
	"damage": "伤害强化",
	"shield_max": "临时护盾",
	"shield_regen": "护盾充能",
	"fire_coverage": "火力覆盖",
	"silent_hunter": "静默猎手",
	"precision_kill": "精准猎杀",
	"cannon_bloodthirst": "嗜血残暴",
	"cannon_rush": "狂飙突进",
	"cannon_vengeance": "为了部落",
	"railgun_damage": "一发入魂",
	"railgun_crit": "命中注定",
	"railgun_multi": "多重射击",
	"laser_duration": "高能光束",
	"laser_width": "高效射击",
	"laser_shield": "护盾中和",
}

const _QUALITY_COLORS: Array[Color] = [
	Color(0.75, 0.75, 0.75),  # 白
	Color(0.25, 0.85, 0.35),  # 绿
	Color(0.25, 0.55, 0.95),  # 蓝
	Color(0.80, 0.30, 0.95),  # 紫
	Color(1.00, 0.60, 0.10),  # 橙
]

const _COIN_GAIN_SHOW_DURATION := 2.0

## ---- HUD 素材路径 ----
const _ASSET_HUD := "res://assets/base/hud/"

const _TEX_BAR_HP     := _ASSET_HUD + "bar_hp_fill.png"
const _TEX_BAR_SHIELD := _ASSET_HUD + "bar_shield_fill.png"
const _TEX_BAR_XP     := _ASSET_HUD + "bar_xp_fill.png"
const _TEX_ICON_HP     := _ASSET_HUD + "icon_hp.png"
const _TEX_ICON_SHIELD := _ASSET_HUD + "icon_shield.png"
const _TEX_ICON_XP     := _ASSET_HUD + "icon_xp.png"
const _TEX_CORNER_TL   := _ASSET_HUD + "corner_tl.png"
const _TEX_CORNER_TR   := _ASSET_HUD + "corner_tr.png"
const _TEX_CORNER_BL   := _ASSET_HUD + "corner_bl.png"
const _TEX_CORNER_BR   := _ASSET_HUD + "corner_br.png"

## 已加载的纹理缓存
var _corner_tex: Dictionary = {}

func _load_tex(path: String) -> Texture2D:
	if path.is_empty():
		return null
	var r = load(path)
	if r is Texture2D:
		return r
	return null

# ============================================================
#  自定义进度条 - 直接 _draw() 渲染，颜色始终一致
# ============================================================
class CustomProgressBar extends Control:
	signal value_changed(value: float)

	var fill_color := Color(1, 0.2, 0.2)
	var bg_color := Color(0.2, 0.05, 0.05)
	var border_color := Color(0.8, 0.2, 0.2, 0.8)
	var corner_radius := 4
	var border_width := 1
	var glow_color := Color()
	var has_glow := false

	## 纹理填充模式：填充颜色叠加在纹理上
	var fill_texture: Texture2D = null
	var _use_texture: bool = false

	var _val: float = 0.0
	var _max_val: float = 100.0
	var _target: float = 0.0
	var _anim_time: float = 0.0
	var _anim_duration: float = 0.25
	var _anim_from: float = 0.0

	func _init() -> void:
		custom_minimum_size.y = 20

	func set_max(v: float) -> void:
		_max_val = maxf(v, 0.001)
		queue_redraw()

	func set_value(v: float, animated := true) -> void:
		_target = clampf(v, 0.0, _max_val)
		if animated and _anim_duration > 0.0:
			_anim_from = _val
			_anim_time = 0.0
		else:
			_val = _target
			queue_redraw()

	func get_value() -> float:
		return _val

	func _process(delta: float) -> void:
		if _anim_time < _anim_duration:
			_anim_time += delta
			var t = minf(_anim_time / _anim_duration, 1.0)
			t = ease(t, 0.15)
			_val = lerpf(_anim_from, _target, t)
			queue_redraw()

	func _draw() -> void:
		var w = size.x
		var h = size.y
		if w <= 0 or h <= 0:
			return

		# 外发光
		if has_glow and glow_color.a > 0:
			var glow_s = glow_color
			glow_s.a *= 0.4
			for i in range(3, 0, -1):
				var rr = corner_radius + i * 2
				draw_rect(Rect2(Vector2.ZERO, size), glow_s, true)

		# 背景
		var bg_rect = Rect2(Vector2.ZERO, size)
		draw_rect(bg_rect, bg_color, true)

		# 填充
		var ratio = _val / _max_val if _max_val > 0.0 else 0.0
		var fill_w = maxf(w * ratio, 0.0)
		if fill_w > 0.0:
			if fill_texture:
				# 纹理模式：只画纹理，左边缘对齐，截取超出部分
				var tex_size = fill_texture.get_size()
				var src_rect = Rect2(0, 0, mini(fill_w, tex_size.x), tex_size.y)
				var dst_rect = Rect2(Vector2.ZERO, Vector2(fill_w, h))
				draw_texture_rect_region(fill_texture, dst_rect, src_rect, Color.WHITE)
			else:
				# 纯色模式
				draw_rect(Rect2(Vector2.ZERO, Vector2(fill_w, h)), fill_color, true)

		# 边框
		var bw = border_width as int
		draw_rect(Rect2(0, 0, w, bw), border_color)
		draw_rect(Rect2(0, h - bw, w, bw), border_color)
		draw_rect(Rect2(0, 0, bw, h), border_color)
		draw_rect(Rect2(w - bw, 0, bw, h), border_color)

# ============================================================
#  HUD 主脚本
# ============================================================
@onready var main_panel: PanelContainer = $BottomCenterAnchor/MainPanel
@onready var main_vbox: VBoxContainer = $BottomCenterAnchor/MainPanel/VBox
@onready var xp_label: Label = $BottomCenterAnchor/MainPanel/VBox/XPRow/XPLabel
@onready var xp_icon: TextureRect = $BottomCenterAnchor/MainPanel/VBox/XPRow/XPIcon
@onready var level_label: Label = $BottomCenterAnchor/MainPanel/VBox/XPRow/LevelLabel

@onready var player_panel: PanelContainer = $ShipInfoPanel
@onready var ship_title: Label = $ShipInfoPanel/ShipInfoVBox/ShipTitle
@onready var hp_label: Label = $ShipInfoPanel/ShipInfoVBox/HPRow/HPLabel
@onready var hp_icon: TextureRect = $ShipInfoPanel/ShipInfoVBox/HPRow/HPIcon
@onready var shield_label: Label = $ShipInfoPanel/ShipInfoVBox/ShieldRow/ShieldLabel
@onready var shield_icon: TextureRect = $ShipInfoPanel/ShipInfoVBox/ShieldRow/ShieldIcon
@onready var race_info_label: Label = $ShipInfoPanel/ShipInfoVBox/RaceInfoLabel
@onready var ship_slots_label: Label = $ShipInfoPanel/ShipInfoVBox/ShipSlotsLabel

@onready var top_weapon_panel: PanelContainer = $TopCenterAnchor/TopWeaponPanel
@onready var top_slot1_name: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot1/WeaponSlot1VBox/Name
@onready var top_slot2: PanelContainer = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot2
@onready var top_slot2_name: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot2/WeaponSlot2VBox/Name
@onready var top_slot3: PanelContainer = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot3
@onready var top_slot3_name: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot3/WeaponSlot3VBox/Name
@onready var top_slot4: PanelContainer = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot4
@onready var top_slot4_name: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot4/WeaponSlot4VBox/Name
@onready var top_slot5: PanelContainer = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot5
@onready var top_slot5_name: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot5/WeaponSlot5VBox/Name
@onready var top_slot6: PanelContainer = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot6
@onready var top_slot6_name: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot6/WeaponSlot6VBox/Name
@onready var top_defense1: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot1/DefenseSlot1VBox/Name
@onready var top_defense2: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot2/DefenseSlot2VBox/Name
@onready var top_defense3: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot3/DefenseSlot3VBox/Name
@onready var top_defense4: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot4/DefenseSlot4VBox/Name
@onready var top_defense5: Label = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot5/DefenseSlot5VBox/Name

@onready var upgrade_list_vbox: VBoxContainer = $BottomRightAnchor/UpgradeListPanel/UpgradeListVBox

@onready var status_vbox: VBoxContainer = $TopRightAnchor/StatusVBox
@onready var timer_label: Label = $TopRightAnchor/StatusVBox/TimerLabel
@onready var coin_gain_label: Label = $TopRightAnchor/StatusVBox/CoinGainLabel
@onready var info_label: Label = $TopRightAnchor/StatusVBox/InfoLabel
@onready var combo_label: Label = $TopRightAnchor/StatusVBox/ComboLabel

@onready var speed_panel: PanelContainer = $SpeedControlPanel
@onready var pause_btn: Button = $SpeedControlPanel/SpeedControlHBox/PauseBtn
@onready var speed1_btn: Button = $SpeedControlPanel/SpeedControlHBox/Speed1Btn
@onready var speed2_btn: Button = $SpeedControlPanel/SpeedControlHBox/Speed2Btn
@onready var speed3_btn: Button = $SpeedControlPanel/SpeedControlHBox/Speed3Btn

var game_scene: Node2D
var _vbox_warned: bool = false
var _prev_coin_display: int = -1
var _coin_floating_timer: float = 0.0
var _coin_floating_amount: int = 0
var _coin_gain_to_show: int = 0
var _coin_gain_timer: float = 0.0

var _current_speed: float = 1.0
var _is_paused: bool = false

# ---- 进度条引用 ----
var hp_bar: CustomProgressBar
var shield_bar: CustomProgressBar
var xp_bar: CustomProgressBar

# ---- 低血量 ----
var _hp_shake_tween: Tween = null
var _was_low_hp: bool = false

# ---- Combo ----
var _combo_tween: Tween = null

# ---- XP 满级脉冲 ----
var _xp_pulse_tween: Tween = null
var _is_max_level: bool = false

# ---- HP 条脉冲光效 ----
var _hp_pulse_tween: Tween = null
var _hp_pulsing: bool = false

func _ready() -> void:
	MobileInput.register_joystick($VirtualJoystick)
	_find_and_replace_progress_bars()
	_apply_all_styles()
	_apply_bar_textures()
	_apply_bar_icons()
	_connect_slot_signals()
	_connect_speed_signals()
	# 角标装饰放最后，不影响主流程
	_load_corner_textures()
	if not _corner_tex.is_empty():
		# _decorate_corner_draw(main_vbox, _corner_tex)  # VBox包含XPRow，跳过避免四角压在经验槽上
		_decorate_corner_draw(player_panel, _corner_tex)
		_decorate_corner_draw(top_weapon_panel, _corner_tex, 0.7)
		# _decorate_corner_draw($BottomCenterAnchor/MainPanel/VBox/XPRow, _corner_tex, 1.5)

func _find_and_replace_progress_bars() -> void:
	# 找到场景中的 ProgressBar 并替换为自定义版本
	var hp_node = $ShipInfoPanel/ShipInfoVBox/HPRow/HPBar
	var shield_node = $ShipInfoPanel/ShipInfoVBox/ShieldRow/ShieldBar
	var xp_node = $BottomCenterAnchor/MainPanel/VBox/XPRow/XPBar

	if hp_node:
		hp_bar = CustomProgressBar.new()
		_copy_bar_props(hp_bar, hp_node)
		hp_node.get_parent().add_child(hp_bar)
		hp_bar.set_owner(hp_node.get_owner())
		hp_node.get_parent().move_child(hp_bar, hp_node.get_index() + 1)
		hp_node.queue_free()

	if shield_node:
		shield_bar = CustomProgressBar.new()
		_copy_bar_props(shield_bar, shield_node)
		shield_node.get_parent().add_child(shield_bar)
		shield_bar.set_owner(shield_node.get_owner())
		shield_node.get_parent().move_child(shield_bar, shield_node.get_index() + 1)
		shield_node.queue_free()

	if xp_node:
		xp_bar = CustomProgressBar.new()
		_copy_bar_props(xp_bar, xp_node)
		xp_node.get_parent().add_child(xp_bar)
		xp_bar.set_owner(xp_node.get_owner())
		xp_node.get_parent().move_child(xp_bar, xp_node.get_index() + 1)
		xp_node.queue_free()

func _copy_bar_props(bar: CustomProgressBar, src: Node) -> void:
	var p = src.get("layout_mode") as int
	if p != -1:
		bar.set("layout_mode", p)
	bar.custom_minimum_size.y = 20
	bar.size_flags_horizontal = SIZE_EXPAND_FILL

# ============================================================
#  样式
# ============================================================
func _apply_all_styles() -> void:
	if not upgrade_list_vbox:
		return

	# 面板发光边框
	_apply_glow_panel(main_panel,    Color(0.06, 0.06, 0.18, 0.95), Color(0.55, 0.55, 1.00), Color(0.25, 0.25, 0.90))
	_apply_glow_panel(player_panel, Color(0.04, 0.04, 0.13, 0.96), Color(0.30, 0.60, 1.00), Color(0.10, 0.30, 0.80))
	_apply_glow_panel(top_weapon_panel, Color(0.04, 0.04, 0.13, 0.90), Color(0.35, 0.45, 0.85), Color(0.15, 0.20, 0.70))

	var upgrade_panel = $BottomRightAnchor/UpgradeListPanel
	if upgrade_panel:
		_apply_glow_panel(upgrade_panel, Color(0.04, 0.04, 0.13, 0.90), Color(0.35, 0.55, 0.90), Color(0.15, 0.30, 0.70))

	if speed_panel:
		var sp = StyleBoxFlat.new()
		sp.bg_color = Color(0.04, 0.06, 0.18, 0.92)
		sp.set_border_width_all(2)
		sp.border_color = Color(0.40, 0.40, 0.80)
		sp.set_corner_radius_all(6)
		speed_panel.add_theme_stylebox_override("panel", sp)

	# 进度条初始样式
	if hp_bar:
		hp_bar.fill_color = Color(1.0, 0.18, 0.18)
		hp_bar.bg_color = Color(0.25, 0.05, 0.05)
		hp_bar.border_color = Color(0.8, 0.1, 0.1, 0.6)
		hp_bar.corner_radius = 4
		hp_bar.queue_redraw()
	if shield_bar:
		shield_bar.fill_color = Color(0.18, 0.55, 1.0)
		shield_bar.bg_color = Color(0.05, 0.15, 0.35)
		shield_bar.border_color = Color(0.1, 0.35, 0.9, 0.6)
		shield_bar.corner_radius = 4
		shield_bar.queue_redraw()
	if xp_bar:
		xp_bar.fill_color = Color(0.18, 0.82, 0.22)
		xp_bar.bg_color = Color(0.05, 0.22, 0.05)
		xp_bar.border_color = Color(0.1, 0.55, 0.1, 0.6)
		xp_bar.corner_radius = 4
		xp_bar.queue_redraw()

	# 字体
	if hp_label:
		hp_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
	if shield_label:
		shield_label.add_theme_color_override("font_color", Color(0.45, 0.72, 1.0))
	if xp_label:
		xp_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.60))
	if level_label:
		level_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
		level_label.add_theme_font_size_override("font_size", 15)
	if race_info_label:
		race_info_label.add_theme_color_override("font_color", Color(0.65, 0.82, 1.0))
	if ship_slots_label:
		ship_slots_label.add_theme_color_override("font_color", Color(0.70, 0.70, 0.90))
		ship_slots_label.add_theme_font_size_override("font_size", 12)

	var title_lbl = upgrade_list_vbox.get_node_or_null("TitleLabel")
	if title_lbl:
		title_lbl.add_theme_color_override("font_color", Color(0.70, 0.90, 1.0))
		title_lbl.add_theme_font_size_override("font_size", 14)
	upgrade_list_vbox.custom_minimum_size.y = 30

	_apply_weapon_slot_base_style()

func _apply_glow_panel(panel: PanelContainer, bg: Color, border: Color, glow: Color) -> void:
	if not panel:
		return
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(2)
	s.border_color = border
	s.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", s)

func _apply_bar_textures() -> void:
	if hp_bar:
		var t = _load_tex(_TEX_BAR_HP)
		if t:
			hp_bar.fill_texture = t
			hp_bar.fill_color = Color(1.0, 1.0, 1.0, 0.0)
			hp_bar.queue_redraw()
		else:
			print("[HUD] HP纹理未加载: ", _TEX_BAR_HP)
	if shield_bar:
		var t = _load_tex(_TEX_BAR_SHIELD)
		if t:
			shield_bar.fill_texture = t
			shield_bar.fill_color = Color(1.0, 1.0, 1.0, 0.0)
			shield_bar.queue_redraw()
		else:
			print("[HUD] 护盾纹理未加载: ", _TEX_BAR_SHIELD)
	if xp_bar:
		var t = _load_tex(_TEX_BAR_XP)
		if t:
			xp_bar.fill_texture = t
			xp_bar.fill_color = Color(1.0, 1.0, 1.0, 0.0)
			xp_bar.queue_redraw()
		else:
			print("[HUD] XP纹理未加载: ", _TEX_BAR_XP)

func _apply_bar_icons() -> void:
	if hp_icon:
		var t = _load_tex(_TEX_ICON_HP)
		if t:
			hp_icon.texture = t
		else:
			print("[HUD] HP图标未加载: ", _TEX_ICON_HP)
	if shield_icon:
		var t = _load_tex(_TEX_ICON_SHIELD)
		if t:
			shield_icon.texture = t
		else:
			print("[HUD] 护盾图标未加载: ", _TEX_ICON_SHIELD)
	if xp_icon:
		var t = _load_tex(_TEX_ICON_XP)
		if t:
			xp_icon.texture = t
		else:
			print("[HUD] XP图标未加载: ", _TEX_ICON_XP)

func _load_corner_textures() -> void:
	## 角标纹理（找不到就无声跳过）
	var paths := {
		"tl": _TEX_CORNER_TL,
		"tr": _TEX_CORNER_TR,
		"bl": _TEX_CORNER_BL,
		"br": _TEX_CORNER_BR,
	}
	for k in paths:
		var t = _load_tex(paths[k])
		if t:
			_corner_tex[k] = t

func _decorate_corner_draw(ctrl: Control, corner_tex: Dictionary, scale: float = 1.0) -> void:
	if not ctrl:
		return
	var tex_tl = corner_tex.get("tl")
	var tex_tr = corner_tex.get("tr")
	var tex_bl = corner_tex.get("bl")
	var tex_br = corner_tex.get("br")
	if not (tex_tl or tex_tr or tex_bl or tex_br):
		return

	var overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.add_child(overlay)

	var t_tl = tex_tl
	var t_tr = tex_tr
	var t_bl = tex_bl
	var t_br = tex_br
	var sc = scale
	overlay.draw.connect(func() -> void:
		if not is_instance_valid(overlay):
			return
		var cs = overlay.size
		if t_tl:
			var ts_tl = t_tl.get_size() * sc
			overlay.draw_texture_rect(t_tl, Rect2(Vector2.ZERO, ts_tl), false)
		if t_tr:
			var ts_tr = t_tr.get_size() * sc
			overlay.draw_texture_rect(t_tr, Rect2(Vector2(cs.x - ts_tr.x, 0), ts_tr), false)
		if t_bl:
			var ts_bl = t_bl.get_size() * sc
			overlay.draw_texture_rect(t_bl, Rect2(Vector2(0, cs.y - ts_bl.y), ts_bl), false)
		if t_br:
			var ts_br = t_br.get_size() * sc
			overlay.draw_texture_rect(t_br, Rect2(Vector2(cs.x - ts_br.x, cs.y - ts_br.y), ts_br), false)
	)
	ctrl.resized.connect(func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_redraw())
	overlay.tree_entered.connect(func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_redraw())

func _apply_weapon_slot_base_style() -> void:
	var slot_paths := [
		"TopWeaponHBox/WeaponSlot1", "TopWeaponHBox/WeaponSlot2",
		"TopWeaponHBox/WeaponSlot3", "TopWeaponHBox/WeaponSlot4",
		"TopWeaponHBox/WeaponSlot5", "TopWeaponHBox/WeaponSlot6",
		"TopWeaponHBox/DefenseSlot1", "TopWeaponHBox/DefenseSlot2",
		"TopWeaponHBox/DefenseSlot3", "TopWeaponHBox/DefenseSlot4",
		"TopWeaponHBox/DefenseSlot5"
	]
	for sp in slot_paths:
		var slot = top_weapon_panel.get_node_or_null(sp)
		if slot:
			_apply_weapon_slot_style(slot, 0)

func _apply_weapon_slot_style(slot: PanelContainer, quality: int) -> void:
	if not slot:
		return
	var qc = _QUALITY_COLORS[clampi(quality, 0, _QUALITY_COLORS.size() - 1)]
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.10, 0.25, 0.92)
	s.set_border_width_all(2)
	s.border_color = qc
	s.set_corner_radius_all(4)
	slot.add_theme_stylebox_override("panel", s)

func _connect_slot_signals() -> void:
	var slot_paths := [
		"TopWeaponHBox/WeaponSlot1", "TopWeaponHBox/WeaponSlot2",
		"TopWeaponHBox/WeaponSlot3", "TopWeaponHBox/WeaponSlot4",
		"TopWeaponHBox/WeaponSlot5", "TopWeaponHBox/WeaponSlot6",
		"TopWeaponHBox/DefenseSlot1", "TopWeaponHBox/DefenseSlot2",
		"TopWeaponHBox/DefenseSlot3", "TopWeaponHBox/DefenseSlot4",
		"TopWeaponHBox/DefenseSlot5"
	]
	for sp in slot_paths:
		var slot = top_weapon_panel.get_node_or_null(sp)
		if slot:
			slot.mouse_entered.connect(_on_slot_mouse_enter.bind(slot))
			slot.mouse_exited.connect(_on_slot_mouse_exit.bind(slot))

func _connect_speed_signals() -> void:
	if pause_btn:
		pause_btn.pressed.connect(_on_pause_pressed)
	if speed1_btn:
		speed1_btn.pressed.connect(_on_speed1_pressed)
	if speed2_btn:
		speed2_btn.pressed.connect(_on_speed2_pressed)
	if speed3_btn:
		speed3_btn.pressed.connect(_on_speed3_pressed)
	_update_speed_buttons()

func _on_pause_pressed() -> void:
	if pause_btn and pause_btn.button_pressed:
		_is_paused = true
		_current_speed = 0.0
		speed_changed.emit(0.0)
	else:
		_is_paused = false
		_current_speed = 1.0
		speed_changed.emit(1.0)
	_update_speed_buttons()

func _on_speed1_pressed() -> void:
	_is_paused = false
	_current_speed = 1.0
	if pause_btn:
		pause_btn.set_pressed_no_signal(false)
	speed_changed.emit(1.0)
	_update_speed_buttons()

func _on_speed2_pressed() -> void:
	_is_paused = false
	_current_speed = 2.0
	if pause_btn:
		pause_btn.set_pressed_no_signal(false)
	speed_changed.emit(2.0)
	_update_speed_buttons()

func _on_speed3_pressed() -> void:
	_is_paused = false
	_current_speed = 3.0
	if pause_btn:
		pause_btn.set_pressed_no_signal(false)
	speed_changed.emit(3.0)
	_update_speed_buttons()

func _update_speed_buttons() -> void:
	var active_color = Color(0.30, 1.00, 0.40)
	var inactive_color = Color(0.45, 0.45, 0.60)
	var all_btns = [pause_btn, speed1_btn, speed2_btn, speed3_btn]
	for btn in all_btns:
		if btn == null:
			continue
		if btn == pause_btn:
			btn.add_theme_color_override("font_color", active_color if _is_paused else inactive_color)
		elif btn == speed1_btn:
			btn.add_theme_color_override("font_color", active_color if _current_speed == 1.0 and not _is_paused else inactive_color)
		elif btn == speed2_btn:
			btn.add_theme_color_override("font_color", active_color if _current_speed == 2.0 else inactive_color)
		elif btn == speed3_btn:
			btn.add_theme_color_override("font_color", active_color if _current_speed == 3.0 else inactive_color)

func _on_slot_mouse_enter(slot: PanelContainer) -> void:
	var s = slot.get_theme_stylebox("panel")
	if s is StyleBoxFlat:
		s.border_color = s.border_color.lightened(0.3)

func _on_slot_mouse_exit(slot: PanelContainer) -> void:
	var quality = slot.get_meta("quality", 0) as int
	_apply_weapon_slot_style(slot, quality)

# ============================================================
#  帧更新
# ============================================================
func _process(delta: float) -> void:
	if _coin_floating_timer > 0.0:
		_coin_floating_timer -= delta
		if _coin_floating_timer <= 0.0:
			_coin_floating_timer = 0.0
	if _coin_gain_timer > 0.0:
		_coin_gain_timer -= delta
		if _coin_gain_timer <= 0.0:
			_coin_gain_timer = 0.0
			_coin_gain_to_show = 0
	if not game_scene or not game_scene.game_manager:
		return
	var gm = game_scene.game_manager

	var player = gm.player if (gm.player and is_instance_valid(gm.player)) else null
	var all_weapon_data: Array = []
	if player:
		if player.get("active_weapons"):
			var weapons: Array = player.get("active_weapons")
			for w in weapons:
				if w:
					all_weapon_data.append({
						"name": w.display_name,
						"level": _get_weapon_upgrade_level(w.weapon_id),
						"quality": w.quality,
					})

	var defense_list: Array = []
	var ship_id = int(GameState.selected_ship_id)
	if ship_id == 0:
		ship_id = ShipData.ShipID.FRIGATE
	var armor_list: Array = GameState.equipped_armor.get(ship_id, [])
	if not (armor_list is Array):
		armor_list = []
	for armor in armor_list:
		if armor is Dictionary:
			defense_list.append({
				"name": armor.get("name", "防御装"),
				"level": armor.get("level", 1),
				"quality": armor.get("quality", 0),
			})

	update_display(
		gm.player_stats.hp,
		gm.player_stats.max_hp,
		gm.player_stats.shield,
		gm.player_stats.shield_max,
		GameState.star_coin,
		GameState.minerals_low + GameState.minerals_mid + GameState.minerals_high,
		gm.kill_count,
		gm.current_xp,
		gm.xp_to_next_level,
		gm.player_level,
		gm.combo_count
	)
	_update_timer_display(gm)
	_update_top_weapon_display(all_weapon_data, defense_list)
	_update_race_and_ship_display()
	_update_upgrade_list_display(gm)

func _get_weapon_upgrade_level(weapon_id) -> int:
	var upgrade_ids = _get_upgrade_ids_for_weapon(weapon_id)
	if upgrade_ids.is_empty():
		return 0
	var total = 0
	var gm = game_scene.game_manager if game_scene else null
	if not gm:
		return 0
	for uid in upgrade_ids:
		total += gm.upgrade_counts.get(uid, 0)
	return total

func _get_upgrade_ids_for_weapon(wid) -> Array:
	var missile_ids = [
		WeaponData.WeaponID.MISSILE, WeaponData.WeaponID.SMALL_MISSILE,
		WeaponData.WeaponID.MEDIUM_MISSILE, WeaponData.WeaponID.LARGE_MISSILE, WeaponData.WeaponID.FLAGSHIP_MISSILE
	]
	var cannon_ids = [
		WeaponData.WeaponID.CANNON, WeaponData.WeaponID.SMALL_CANNON,
		WeaponData.WeaponID.MEDIUM_CANNON, WeaponData.WeaponID.LARGE_CANNON, WeaponData.WeaponID.FLAGSHIP_CANNON
	]
	var railgun_ids = [
		WeaponData.WeaponID.RAILGUN, WeaponData.WeaponID.SMALL_RAILGUN,
		WeaponData.WeaponID.MEDIUM_RAILGUN, WeaponData.WeaponID.LARGE_RAILGUN, WeaponData.WeaponID.FLAGSHIP_RAILGUN
	]
	var laser_ids = [
		WeaponData.WeaponID.LASER, WeaponData.WeaponID.SMALL_LASER,
		WeaponData.WeaponID.MEDIUM_LASER, WeaponData.WeaponID.LARGE_LASER, WeaponData.WeaponID.FLAGSHIP_LASER
	]
	if wid in missile_ids:
		return ["fire_coverage", "silent_hunter", "precision_kill"]
	elif wid in cannon_ids:
		return ["cannon_bloodthirst", "cannon_rush", "cannon_vengeance"]
	elif wid in railgun_ids:
		return ["railgun_multi", "railgun_crit", "railgun_damage"]
	elif wid in laser_ids:
		return ["laser_duration", "laser_width", "laser_shield"]
	return []

# ============================================================
#  武器/防御槽
# ============================================================
func _update_top_weapon_display(all_weapon_data: Array, defense_list: Array) -> void:
	var slot_nodes = [
		{"panel": null, "name_label": top_slot1_name},
		{"panel": null, "name_label": top_slot2_name},
		{"panel": null, "name_label": top_slot3_name},
		{"panel": null, "name_label": top_slot4_name},
		{"panel": null, "name_label": top_slot5_name},
		{"panel": null, "name_label": top_slot6_name},
	]
	slot_nodes[0]["panel"] = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot1
	slot_nodes[1]["panel"] = top_slot2
	slot_nodes[2]["panel"] = top_slot3
	slot_nodes[3]["panel"] = top_slot4
	slot_nodes[4]["panel"] = top_slot5
	slot_nodes[5]["panel"] = top_slot6

	for i in range(slot_nodes.size()):
		var slot = slot_nodes[i]
		var panel: Node = slot["panel"]
		var name_lbl: Label = slot["name_label"]
		if not panel or not name_lbl:
			continue
		if i < all_weapon_data.size():
			var wd = all_weapon_data[i]
			panel.visible = true
			panel.set_meta("quality", wd.get("quality", 0))
			name_lbl.text = str(wd.get("name", "?"))
			name_lbl.add_theme_color_override("font_color", EquipmentData.get_quality_color(wd.get("quality", 0)))
			_apply_weapon_slot_style(panel as PanelContainer, wd.get("quality", 0))
		else:
			panel.visible = false

	var defense_slots = [top_defense1, top_defense2, top_defense3, top_defense4, top_defense5]
	for idx in range(defense_slots.size()):
		var name_lbl: Label = defense_slots[idx]
		if not name_lbl:
			continue
		var slot_panel: Node = null
		match idx:
			0: slot_panel = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot1
			1: slot_panel = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot2
			2: slot_panel = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot3
			3: slot_panel = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot4
			4: slot_panel = $TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/DefenseSlot5
		if slot_panel:
			slot_panel.visible = (idx < defense_list.size())
			slot_panel.set_meta("quality", defense_list[idx].get("quality", 0) if idx < defense_list.size() else 0)
		if idx < defense_list.size():
			var armor = defense_list[idx]
			name_lbl.text = str(armor.get("name", "防御装"))
			name_lbl.add_theme_color_override("font_color", EquipmentData.get_quality_color(armor.get("quality", 0)))
			_apply_weapon_slot_style(slot_panel as PanelContainer, armor.get("quality", 0))
		else:
			name_lbl.text = "空槽位"
			name_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.55))
			_apply_weapon_slot_style(slot_panel as PanelContainer, 0)

# ============================================================
#  升级列表
# ============================================================
func _update_upgrade_list_display(gm) -> void:
	if not upgrade_list_vbox:
		if not _vbox_warned:
			_vbox_warned = true
		return

	var current_keys = gm.upgrade_counts.keys()
	var has_any_upgrade = false
	for k in current_keys:
		if gm.upgrade_counts[k] > 0:
			has_any_upgrade = true
			break

	var upgrade_panel = $BottomRightAnchor/UpgradeListPanel
	if upgrade_panel:
		upgrade_panel.visible = has_any_upgrade

	var existing_labels: Array = []
	for i in range(2, upgrade_list_vbox.get_child_count()):
		var child = upgrade_list_vbox.get_child(i)
		if child is Label:
			existing_labels.append(child)

	var label_idx = 0
	for key in current_keys:
		var count = gm.upgrade_counts.get(key, 0)
		if count <= 0:
			continue
		var display_name = UPGRADE_NAME_MAP.get(key, key)
		var text = "%s Lv.%d" % [display_name, count]

		var lbl: Label
		if label_idx < existing_labels.size():
			lbl = existing_labels[label_idx]
			lbl.text = text
			lbl.visible = true
		else:
			lbl = Label.new()
			lbl.text = text
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
			upgrade_list_vbox.add_child(lbl)
		label_idx += 1

	for i in range(label_idx, existing_labels.size()):
		existing_labels[i].visible = false

# ============================================================
#  主更新函数
# ============================================================
func update_display(p_hp: int, p_max_hp: int, p_shield: float, p_shield_max: float, p_coin: int, p_minerals: int, p_kills: int, p_xp: float, p_xp_max: float, p_level: int, p_combo: int = 0) -> void:
	var hp_ratio = float(p_hp) / float(p_max_hp) if p_max_hp > 0 else 0.0

	if hp_bar:
		hp_bar.set_max(maxf(p_max_hp, 1.0))
		hp_bar.set_value(clampf(p_hp, 0, p_max_hp))
		hp_label.text = "%d" % p_hp
		# HP 渐变：满血偏绿，低血偏红
		var hp_fill = Color(
			1.0,
			lerpf(0.10, 0.72, hp_ratio),
			lerpf(0.08, 0.50, hp_ratio)
		)
		hp_bar.fill_color = hp_fill
		hp_bar.border_color = Color(hp_fill.r * 0.9, hp_fill.g * 0.15, hp_fill.b * 0.15, 0.7)
		hp_bar.queue_redraw()

	if shield_bar:
		shield_bar.set_max(maxf(p_shield_max, 0.1))
		shield_bar.set_value(clampf(p_shield, 0, p_shield_max))
		shield_label.text = "%.0f" % p_shield
		var sh_ratio = p_shield / p_shield_max if p_shield_max > 0.0 else 0.0
		var sh_fill = Color(
			lerpf(0.05, 0.18, sh_ratio),
			lerpf(0.40, 0.58, sh_ratio),
			1.0
		)
		shield_bar.fill_color = sh_fill
		shield_bar.border_color = Color(0.05, 0.3, 0.9, 0.7)
		shield_bar.queue_redraw()

	if xp_bar:
		xp_bar.set_max(maxf(p_xp_max, 1.0))
		xp_bar.set_value(clampf(p_xp, 0, p_xp_max))
		xp_label.text = "%.0f" % p_xp

		var is_max = (p_level >= 100 and p_xp_max > 0 and p_xp >= p_xp_max)
		if is_max and not _is_max_level:
			_is_max_level = true
			_start_xp_pulse()
		elif not is_max and _is_max_level:
			_is_max_level = false
			_stop_xp_pulse()
		if is_max:
			xp_bar.fill_color = Color(1.0, 0.82, 0.08)
			xp_bar.border_color = Color(0.9, 0.6, 0.0, 0.7)
			xp_bar.has_glow = true
			xp_bar.glow_color = Color(1.0, 0.8, 0.0, 0.3)
		else:
			xp_bar.fill_color = Color(0.18, 0.82, 0.22)
			xp_bar.border_color = Color(0.08, 0.55, 0.08, 0.7)
			xp_bar.has_glow = false
		xp_bar.queue_redraw()

	if level_label:
		level_label.text = "Lv.%d" % p_level

	if info_label:
		info_label.text = "Level: %d | Kills: %d | 星币: %d" % [p_level, p_kills, p_coin]
		info_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	# 低血量脉冲
	var is_low_hp = (hp_ratio <= 0.25 and hp_ratio > 0.0)
	if is_low_hp and not _was_low_hp:
		_was_low_hp = true
		_start_hp_pulse()
	elif not is_low_hp and _was_low_hp:
		_was_low_hp = false
		_stop_hp_pulse()

	# 金币
	if _prev_coin_display >= 0 and p_coin > _prev_coin_display:
		_coin_floating_amount += (p_coin - _prev_coin_display)
		if _coin_floating_timer <= 0.0:
			_coin_floating_timer = 0.6
			_coin_gain_to_show = _coin_floating_amount
			_coin_gain_timer = _COIN_GAIN_SHOW_DURATION
			_spawn_coin_floating_text(_coin_floating_amount)
			_coin_floating_amount = 0
	_prev_coin_display = p_coin

	if coin_gain_label:
		if _coin_gain_to_show > 0 and _coin_gain_timer > 0.0:
			coin_gain_label.text = "+%d" % _coin_gain_to_show
			coin_gain_label.add_theme_color_override("font_color", Color(0.30, 1.0, 0.40))
			coin_gain_label.add_theme_font_size_override("font_size", 16)
		else:
			coin_gain_label.text = ""

	# Combo
	if combo_label:
		if p_combo >= 3:
			var prev_text = combo_label.text
			var new_text = "x%d COMBO!" % p_combo
			if prev_text != new_text:
				_trigger_combo_animation()
			combo_label.text = new_text
			if p_combo >= 10:
				combo_label.add_theme_color_override("font_color", Color(1.0, 0.80, 0.00))
				combo_label.add_theme_font_size_override("font_size", 20)
			elif p_combo >= 5:
				combo_label.add_theme_color_override("font_color", Color(1.0, 1.00, 0.60))
				combo_label.add_theme_font_size_override("font_size", 17)
			else:
				combo_label.add_theme_color_override("font_color", Color(0.70, 1.00, 0.70))
				combo_label.add_theme_font_size_override("font_size", 14)
		else:
			combo_label.text = ""

# ============================================================
#  HP 低血量脉冲
# ============================================================
func _start_hp_pulse() -> void:
	if _hp_pulse_tween and _hp_pulse_tween.is_valid():
		_hp_pulse_tween.kill()
	_hp_pulse_tween = create_tween()
	_hp_pulse_tween.set_loops()
	_hp_pulse_tween.tween_property(hp_bar, "modulate", Color(2.0, 0.5, 0.5, 1.0), 0.30)
	_hp_pulse_tween.tween_property(hp_bar, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.30)
	_hp_pulsing = true

func _stop_hp_pulse() -> void:
	if _hp_pulse_tween and _hp_pulse_tween.is_valid():
		_hp_pulse_tween.kill()
		_hp_pulse_tween = null
	if hp_bar:
		hp_bar.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_hp_pulsing = false

# ============================================================
#  Combo 弹跳
# ============================================================
func _trigger_combo_animation() -> void:
	if _combo_tween and _combo_tween.is_valid():
		_combo_tween.kill()
	_combo_tween = create_tween()
	_combo_tween.set_parallel(true)
	_combo_tween.tween_property(combo_label, "scale", Vector2(1.6, 1.6), 0.08).set_ease(Tween.EASE_OUT)
	_combo_tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.18).set_ease(Tween.EASE_IN)
	_combo_tween.tween_property(combo_label, "modulate", Color(1.0, 1.8, 1.0, 1.0), 0.06)
	_combo_tween.tween_property(combo_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)

# ============================================================
#  XP 满级金色脉冲
# ============================================================
func _start_xp_pulse() -> void:
	if _xp_pulse_tween and _xp_pulse_tween.is_valid():
		_xp_pulse_tween.kill()
	_xp_pulse_tween = create_tween()
	_xp_pulse_tween.set_loops()
	_xp_pulse_tween.tween_property(xp_bar, "modulate", Color(1.5, 1.3, 0.3, 1.0), 0.50)
	_xp_pulse_tween.tween_property(xp_bar, "modulate", Color(1.0, 0.85, 0.10, 1.0), 0.50)
	if xp_label:
		_xp_pulse_tween.tween_property(xp_label, "modulate", Color(1.5, 1.3, 0.3, 1.0), 0.50)
		_xp_pulse_tween.tween_property(xp_label, "modulate", Color(0.55, 1.0, 0.60, 1.0), 0.50)
	if level_label:
		_xp_pulse_tween.tween_property(level_label, "modulate", Color(1.5, 1.3, 0.3, 1.0), 0.50)
		_xp_pulse_tween.tween_property(level_label, "modulate", Color(0.85, 1.0, 0.85, 1.0), 0.50)

func _stop_xp_pulse() -> void:
	if _xp_pulse_tween and _xp_pulse_tween.is_valid():
		_xp_pulse_tween.kill()
		_xp_pulse_tween = null
	if xp_bar:
		xp_bar.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if xp_label:
		xp_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if level_label:
		level_label.modulate = Color(1.0, 1.0, 1.0, 1.0)

# ============================================================
#  其他
# ============================================================
func _update_race_and_ship_display() -> void:
	if not game_scene or not game_scene.game_manager:
		return
	var gm = game_scene.game_manager
	if not gm.player or not is_instance_valid(gm.player):
		return

	if race_info_label:
		var race = RaceData.get_race(GameState.selected_race_id)
		if race:
			race_info_label.text = "种族: " + race.display_name
		else:
			race_info_label.text = "种族: -"

	if ship_slots_label:
		var ship = ShipData.get_ship(GameState.selected_ship_id)
		if ship:
			var ship_id = int(GameState.selected_ship_id)
			if ship_id == 0:
				ship_id = ShipData.ShipID.FRIGATE
			var weapon_list = GameState.equipped_weapons.get(ship_id, [])
			var weapon_count = weapon_list.size() if weapon_list is Array else 0
			var w_max = ship.upgraded_weapon_slots if GameState.upgraded_ships.get(ship_id, false) else ship.weapon_slot_count
			var armor_list: Array = GameState.equipped_armor.get(ship_id, [])
			var armor_count = armor_list.size() if armor_list is Array else 0
			var a_max = ship.upgraded_armor_slots if GameState.upgraded_ships.get(ship_id, false) else ship.armor_slot_count
			ship_slots_label.text = "武:%d/%d | 防:%d/%d" % [weapon_count, w_max, armor_count, a_max]
		else:
			ship_slots_label.text = "武:0/? | 防:0/?"

func set_paused_state(paused: bool) -> void:
	if paused and not _is_paused:
		_is_paused = true
		if pause_btn:
			pause_btn.set_pressed_no_signal(true)
	elif not paused and _is_paused:
		_is_paused = false
		if pause_btn:
			pause_btn.set_pressed_no_signal(false)
	_update_speed_buttons()

func setup(gs: Node2D) -> void:
	game_scene = gs
	_prev_coin_display = -1
	_coin_floating_timer = 0.0
	_coin_floating_amount = 0
	_coin_gain_to_show = 0
	_coin_gain_timer = 0.0
	_was_low_hp = false
	_is_max_level = false
	_current_speed = 1.0
	_is_paused = false
	if pause_btn:
		pause_btn.set_pressed_no_signal(false)
	_update_speed_buttons()
	update_display(100, 100, 50.0, 50.0, 0, 0, 0, 0.0, 10.0, 1)

func _update_timer_display(gm) -> void:
	if not timer_label:
		return
	if not gm.has_timer:
		timer_label.visible = false
		return

	if gm.is_unlimited_mode:
		var elapsed: float = gm.run_time_elapsed
		var mins := int(elapsed) / 60
		var secs := int(elapsed) % 60
		timer_label.text = "+%02d:%02d" % [mins, secs]
		timer_label.add_theme_color_override("font_color", Color(0.30, 1.00, 0.50))
		timer_label.visible = true
	elif gm.time_remaining > 0:
		var mins := int(gm.time_remaining) / 60
		var secs := int(gm.time_remaining) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
		timer_label.visible = true
		if gm.time_remaining <= 30.0:
			timer_label.add_theme_color_override("font_color", Color(1.0, 0.30, 0.30))
		elif gm.time_remaining <= 60.0:
			timer_label.add_theme_color_override("font_color", Color(1.0, 0.80, 0.00))
		else:
			timer_label.add_theme_color_override("font_color", Color(0.80, 0.80, 1.00))
	else:
		timer_label.visible = false

func _spawn_coin_floating_text(amount: int) -> void:
	if not coin_gain_label:
		return
	var label = Label.new()
	label.text = "+%d" % amount
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.30, 1.00, 0.40))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.offset_top = coin_gain_label.global_position.y - 20.0
	label.offset_left = coin_gain_label.global_position.x + 20.0
	label.offset_right = label.offset_left + 200.0
	label.offset_bottom = label.offset_top + 30.0
	add_child(label)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "offset_top", label.offset_top - 30.0, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)

	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.7
	timer.timeout.connect(label.queue_free)
	add_child(timer)
	timer.start()
