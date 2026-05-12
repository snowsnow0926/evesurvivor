class_name BossBase
extends EnemyBase

## BOSS基类。所有BOSS继承此类。
## 封装了BOSS的通用逻辑：狂暴模式、接触伤害、子弹攻击、死亡奖励等。
## 子类只需：
##   1. 在 _ready() 中调用 super._ready()
##   2. 覆盖 _get_attack_pattern() 实现独特攻击
##   3. 在 setup_boss() 中配置战斗参数

const _SCENE_EXP_ORB: PackedScene = preload("res://scenes/ExpOrb.tscn")

# === Boss Entry ===
var _entry: BossEntry
var _loot_tonnage_chapter: int = 1

# === Combat State ===
var is_rage: bool = false
var fire_timer: float = 0.0
var fire_interval_normal: float = 1.5
var fire_interval_rage: float = 1.0
var contact_timer: float = 0.0

# === Bullet Config (override per boss) ===
var bullet_speed: float = 400.0
var bullet_damage: float = 10.0

# === Bullet Scene ===
var _bullet_scene: PackedScene = preload("res://scenes/BossBullet.tscn")

func _ready() -> void:
	super._ready()


func setup_from_entry(entry: BossEntry) -> void:
	_entry = entry

	_base_tint = entry.base_tint
	_visual_scale = entry.visual_scale
	_icon_id = entry.icon_id
	tonnage = entry.tonnage

	_dmg_number_font_size_normal = entry.damage_number_font_size_normal
	_dmg_number_font_size_crit = entry.damage_number_font_size_crit
	_dmg_number_offset_x_range = entry.damage_number_offset_x_range
	_dmg_number_offset_y = entry.damage_number_offset_y
	_dmg_number_anim_offset = entry.damage_number_anim_offset
	_dmg_number_anim_duration = entry.damage_number_anim_duration
	_dmg_number_color_normal = entry.damage_number_color_normal
	_dmg_number_color_crit = entry.damage_number_color_crit

	_death_particle_color = entry.particle_color
	_death_particle_count = entry.death_particle_count
	_death_particle_lifetime = entry.death_particle_lifetime
	_death_particle_velocity_min = entry.death_particle_velocity_min
	_death_particle_velocity_max = entry.death_particle_velocity_max
	_death_particle_scale_min = entry.death_particle_scale_min
	_death_particle_scale_max = entry.death_particle_scale_max
	_death_burst_count = entry.death_burst_count

	_hit_flash_intensity = entry.hit_flash_intensity
	_hp_bar_max_width = entry.hp_bar_width

	collision_radius_override = entry.collision_radius
	bullet_speed = entry.bullet_speed
	bullet_damage = entry.bullet_damage
	fire_interval_normal = 1.5
	fire_interval_rage = 1.0


var collision_radius_override: float = 40.0


func setup_boss(gm: Node2D, b_hp: float, b_damage: float, b_speed: float, b_shield: float, tonnage_chapter: int) -> void:
	_loot_tonnage_chapter = tonnage_chapter
	game_manager = gm
	max_hp = b_hp
	hp = b_hp
	enemy_shield_max = b_shield
	enemy_shield = b_shield
	damage = b_damage
	move_speed = b_speed
	is_rage = false
	fire_timer = 0.0
	contact_timer = 0.0

	if _entry != null:
		_chapter_icon_override = _entry.icon_id
	_apply_chapter_icon()


func _process_combat(delta: float) -> void:
	var player = _get_player()
	if not is_instance_valid(player):
		return

	_process_contact_damage(player)
	_process_rage_check()
	_process_attack_pattern(delta)


func _process_contact_damage(player: Node2D) -> void:
	var contact_cooldown = 0.5 if _entry == null else _entry.contact_cooldown
	var dmg = 15.0 if _entry == null else _entry.collision_damage
	contact_timer += get_process_delta_time()
	if contact_timer >= contact_cooldown:
		contact_timer = 0.0
		var radius = collision_radius_override
		if global_position.distance_to(player.global_position) < radius:
			if player.has_method("on_player_take_damage"):
				player.on_player_take_damage(dmg)


func _process_rage_check() -> void:
	if _entry == null:
		return
	var threshold = _entry.rage_hp_threshold
	if hp / max_hp <= threshold and not is_rage:
		_enter_rage_mode()


func _process_attack_pattern(delta: float) -> void:
	fire_timer += delta
	var interval = fire_interval_rage if is_rage else fire_interval_normal
	if fire_timer >= interval:
		fire_timer = 0.0
		_execute_attack_pattern()


func _enter_rage_mode() -> void:
	is_rage = true
	if _entry != null:
		_base_tint = _entry.rage_tint
		move_speed *= 1.2
	_update_shader_params()


func _execute_attack_pattern() -> void:
	pass


func _fire_spread(bullet_count: int = 3, angle_spread: float = 15.0) -> void:
	var player = _get_player()
	if not is_instance_valid(player):
		return
	var bullet_root = _get_bullet_root()
	if not bullet_root or not is_instance_valid(bullet_root):
		return

	var base_angle = global_position.angle_to_point(player.global_position)
	var count = bullet_count * 2 if is_rage else bullet_count
	var spread_rad = deg_to_rad(angle_spread * 2) if is_rage else deg_to_rad(angle_spread)
	var total_spread = spread_rad * (count - 1)

	for i in range(count):
		var angle = base_angle - total_spread / 2.0 + spread_rad * i
		var dir = Vector2.from_angle(angle)
		_spawn_bullet(dir)


func _fire_ring(bullet_count: int = 8, speed: float = -1.0, dmg: float = -1.0) -> void:
	var bullet_root = _get_bullet_root()
	if not bullet_root or not is_instance_valid(bullet_root):
		return
	var spd = bullet_speed if speed < 0 else speed
	var damage = bullet_damage if dmg < 0 else dmg
	var step = TAU / bullet_count
	for i in range(bullet_count):
		var dir = Vector2.from_angle(step * i)
		_spawn_bullet(dir, spd, damage)


func _fire_aimed_shot(count: int = 3, interval: float = 0.15) -> void:
	var player = _get_player()
	if not is_instance_valid(player):
		return
	var bullet_root = _get_bullet_root()
	if not bullet_root or not is_instance_valid(bullet_root):
		return

	var dir = global_position.direction_to(player.global_position)
	var spread = deg_to_rad(5.0)
	for i in range(count):
		await get_tree().create_timer(interval * i).timeout
		if not is_instance_valid(self):
			return
		var offset_angle = randf_range(-spread, spread)
		var final_dir = dir.rotated(offset_angle)
		_spawn_bullet(final_dir)


func _spawn_bullet(dir: Vector2, speed: float = -1.0, dmg: float = -1.0) -> void:
	var bullet_root = _get_bullet_root()
	if not bullet_root or not is_instance_valid(bullet_root):
		return
	var spd = bullet_speed if speed < 0 else speed
	var damage = bullet_damage if dmg < 0 else dmg
	var bullet = _bullet_scene.instantiate()
	bullet_root.add_child(bullet)
	bullet.global_position = global_position
	var player = _get_player()
	bullet.setup(dir, damage, spd, game_manager, player)


func _get_bullet_root() -> Node2D:
	if game_manager == null:
		return null
	var bullet_root = game_manager.get("bullet_root")
	if bullet_root == null or not is_instance_valid(bullet_root):
		return null
	return bullet_root


func _spawn_death_rewards() -> void:
	SoundManager.play_sfx("boss_death")
	var exp_root = _get_exp_orb_root()
	if exp_root == null:
		return
	var count = 10 if _entry == null else _entry.death_exp_orb_count
	for i in range(count):
		var angle = TAU * i / count
		var orb = _SCENE_EXP_ORB.instantiate()
		orb.set_game_manager(game_manager)
		orb.global_position = global_position + Vector2.from_angle(angle) * 60.0
		exp_root.call_deferred("add_child", orb)


func _get_exp_orb_root() -> Node2D:
	if game_manager == null:
		return null
	var root = game_manager.get("exp_orb_root")
	if root == null or not is_instance_valid(root):
		return null
	return root


func _die() -> void:
	_spawn_death_effect()
	_spawn_wreck()
	_spawn_death_rewards()
	if game_manager and is_instance_valid(game_manager):
		game_manager.spawn_boss_loot(self)
		game_manager.try_drop_equipment(self)
	enemy_dead.emit(self, "boss")
	queue_free()


func _get_enemy_type() -> String:
	return "boss"


func _get_loot_tonnage_chapter() -> int:
	return _loot_tonnage_chapter


func get_boss_id() -> String:
	return _entry.boss_id if _entry != null else ""


func get_boss_name_zh() -> String:
	return _entry.name_zh if _entry != null else ""


func get_boss_name_en() -> String:
	return _entry.name_en if _entry != null else ""
