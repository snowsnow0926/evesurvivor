extends BossBase

## 虚空领主。第1章BOSS。
## 攻击模式：扇形弹幕（3发普通 / 5发狂暴），60%HP进入狂暴。

func _ready() -> void:
	_base_tint = Color(0.5, 0.0, 0.5)
	_visual_scale = 1.2
	_icon_id = "boss_void"
	tonnage = "boss"
	_hp_bar_max_width = 102.0
	_hit_flash_intensity = 3.0
	_dmg_number_font_size_normal = 20
	_dmg_number_font_size_crit = 28
	_dmg_number_offset_x_range = 40.0
	_dmg_number_offset_y = -60.0
	_dmg_number_anim_offset = 80.0
	_dmg_number_anim_duration = 0.8
	_dmg_number_color_normal = Color(1.0, 0.3, 0.3)
	_dmg_number_color_crit = Color(1.0, 0.8, 0.0)
	_death_particle_color = Color(0.5, 0.0, 0.5, 1.0)
	_death_particle_count = 40
	_death_particle_lifetime = 1.0
	_death_particle_velocity_min = 100.0
	_death_particle_velocity_max = 300.0
	_death_particle_scale_min = 5.0
	_death_particle_scale_max = 15.0
	_death_burst_count = 5
	super._ready()


func _execute_attack_pattern() -> void:
	_fire_spread(3, 15.0)
