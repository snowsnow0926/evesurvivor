extends Node
## 全局性能配置 — 移动端自动降质，PC 保持完整效果
## 使用 Engine.has_feature("mobile") 区分平台
## 所有需要条件化的性能参数集中在这里配置

var is_mobile: bool = _detect_mobile()

func _detect_mobile() -> bool:
	var os_name := OS.get_name()
	return os_name in ["Android", "iOS", "iPhone", "iPad"]

# 星空背景密度倍率（0.25 = 降为 PC 的 25%）
var starfield_density_mult: float = 1.0

# 粒子数量
var death_particle_count: int = 30
var death_particle_lifetime: float = 0.5
var explosion_particle_count: int = 30
var wreck_smoke_particle_count: int = 30

# 视觉效果开关
var show_damage_numbers: bool = true
var show_death_effects: bool = true
var show_wrecks: bool = true
var wreck_smoke_enabled: bool = true
var show_hit_flash: bool = true

# 伤害数字对象池大小
var damage_number_pool_size: int = 50

# 弹幕生成间隔（秒）— 移动端加倍，降低弹幕密度
var bullet_spawn_interval_mult: float = 1.0

func _ready() -> void:
	if is_mobile:
		_apply_mobile_defaults()
	print("[Performance] is_mobile=%s starfield=%.0f%% death_particles=%d explosion=%d wrecks=%s smoke=%s" % [
		is_mobile, starfield_density_mult * 100, death_particle_count,
		explosion_particle_count, show_wrecks, wreck_smoke_enabled
	])

func _apply_mobile_defaults() -> void:
	starfield_density_mult = 0.25
	death_particle_count = 15
	explosion_particle_count = 15
	show_wrecks = false
	wreck_smoke_enabled = false
	show_damage_numbers = true
	show_death_effects = true
	show_hit_flash = true
	bullet_spawn_interval_mult = 1.0

## 便捷方法：获取粒子数（移动端应用全局上限）
func get_death_particle_count(base: int) -> int:
	if is_mobile:
		return mini(death_particle_count, base)
	return base

func get_explosion_particle_count(base: int) -> int:
	if is_mobile:
		return mini(explosion_particle_count, base)
	return base
