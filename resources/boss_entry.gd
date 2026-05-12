class_name BossEntry
extends RefCounted

## BOSS元数据包。定义一个BOSS的所有配置数据，由 BossRegistry 统一管理。
## 新增BOSS时，在 BossRegistry 中创建 BossEntry 并注册即可。

# === 身份 ===
var boss_id: String = ""
var name_zh: String = ""
var name_en: String = ""
var icon_id: String = ""
var portrait_path: String = ""
var chapter: int = 1
var tonnage: String = "boss"

# === 视觉 ===
var base_tint: Color = Color(0.5, 0.0, 0.5)
var rage_tint: Color = Color(1.0, 0.2, 0.2)
var particle_color: Color = Color(0.5, 0.0, 0.5, 1.0)
var visual_scale: float = 1.2
var hp_bar_width: float = 102.0
var hit_flash_intensity: float = 3.0
var damage_number_font_size_normal: int = 20
var damage_number_font_size_crit: int = 28
var damage_number_offset_x_range: float = 40.0
var damage_number_offset_y: float = -60.0
var damage_number_anim_offset: float = 80.0
var damage_number_anim_duration: float = 0.8
var damage_number_color_normal: Color = Color(1.0, 0.3, 0.3)
var damage_number_color_crit: Color = Color(1.0, 0.8, 0.0)

# === 战斗 ===
var rage_hp_threshold: float = 0.6
var collision_radius: float = 40.0
var collision_damage: float = 15.0
var contact_cooldown: float = 0.5
var move_speed: float = 80.0
var bullet_scene_path: String = "res://scenes/BossBullet.tscn"
var bullet_speed: float = 400.0
var bullet_damage: float = 10.0

# === 死亡特效 ===
var death_particle_count: int = 40
var death_burst_count: int = 5
var death_particle_lifetime: float = 1.0
var death_particle_velocity_min: float = 100.0
var death_particle_velocity_max: float = 300.0
var death_particle_scale_min: float = 5.0
var death_particle_scale_max: float = 15.0
var death_exp_orb_count: int = 10

func _init(
	p_boss_id: String = "",
	p_name_zh: String = "",
	p_name_en: String = "",
	p_icon_id: String = "",
	p_portrait_path: String = "",
	p_chapter: int = 1,
	p_tonnage: String = "boss",
	p_base_tint: Color = Color(0.5, 0.0, 0.5),
	p_rage_tint: Color = Color(1.0, 0.2, 0.2),
	p_particle_color: Color = Color(0.5, 0.0, 0.5, 1.0),
	p_visual_scale: float = 1.2,
	p_hp_bar_width: float = 102.0,
	p_hit_flash: float = 3.0,
	p_rage_threshold: float = 0.6,
	p_collision_radius: float = 40.0,
	p_collision_damage: float = 15.0,
	p_contact_cooldown: float = 0.5,
	p_move_speed: float = 80.0,
	p_bullet_scene: String = "res://scenes/BossBullet.tscn",
	p_bullet_speed: float = 400.0,
	p_bullet_damage: float = 10.0,
	p_death_particle_count: int = 40,
	p_death_burst_count: int = 5,
	p_death_exp_orb_count: int = 10
) -> void:
	boss_id = p_boss_id
	name_zh = p_name_zh
	name_en = p_name_en
	icon_id = p_icon_id
	portrait_path = p_portrait_path
	chapter = p_chapter
	tonnage = p_tonnage
	base_tint = p_base_tint
	rage_tint = p_rage_tint
	particle_color = p_particle_color
	visual_scale = p_visual_scale
	hp_bar_width = p_hp_bar_width
	hit_flash_intensity = p_hit_flash
	rage_hp_threshold = p_rage_threshold
	collision_radius = p_collision_radius
	collision_damage = p_collision_damage
	contact_cooldown = p_contact_cooldown
	move_speed = p_move_speed
	bullet_scene_path = p_bullet_scene
	bullet_speed = p_bullet_speed
	bullet_damage = p_bullet_damage
	death_particle_count = p_death_particle_count
	death_burst_count = p_death_burst_count
	death_exp_orb_count = p_death_exp_orb_count


func get_bullet_scene() -> PackedScene:
	if ResourceLoader.exists(bullet_scene_path):
		return load(bullet_scene_path) as PackedScene
	return preload("res://scenes/BossBullet.tscn")


func has_portrait() -> bool:
	return portrait_path != "" and ResourceLoader.exists(portrait_path)
