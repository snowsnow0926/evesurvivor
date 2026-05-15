extends BossBase

## 钱破军。第1章第6关BOSS。
## Phase 1 (>40% HP): 环形弹幕(8发) + 正面高伤害直线弹
## Phase 2 (<40% HP 狂暴): 环形弹幕(16发) + 多发直线弹，攻速加快

var _attack_phase: int = 0
var _attack_timer: float = 0.0

func _ready() -> void:
	_base_tint = Color(0.8, 0.67, 0.0)
	_visual_scale = 1.3
	_icon_id = "boss_qianpojun"
	tonnage = "boss"
	_hp_bar_max_width = 102.0
	_hit_flash_intensity = 1.5
	_dmg_number_font_size_normal = 22
	_dmg_number_font_size_crit = 30
	_dmg_number_offset_x_range = 45.0
	_dmg_number_offset_y = -65.0
	_dmg_number_anim_offset = 85.0
	_dmg_number_anim_duration = 0.8
	_dmg_number_color_normal = Color(1.0, 0.85, 0.0)
	_dmg_number_color_crit = Color(1.0, 0.3, 0.0)
	_death_particle_color = Color(0.8, 0.67, 0.0, 1.0)
	_death_particle_count = 50
	_death_particle_lifetime = 1.2
	_death_particle_velocity_min = 120.0
	_death_particle_velocity_max = 350.0
	_death_particle_scale_min = 6.0
	_death_particle_scale_max = 18.0
	_death_burst_count = 6
	super._ready()


func _process_combat(delta: float) -> void:
	_process_movement(delta)
	_process_contact_damage(_get_player())
	_process_rage_check()
	_process_attack_pattern(delta)


func _process_movement(delta: float) -> void:
	var player = _get_player()
	if not is_instance_valid(player):
		return
	var direction := global_position.direction_to(player.global_position)
	global_position += direction * move_speed * delta


func _process_attack_pattern(delta: float) -> void:
	_attack_timer += delta
	var interval := 1.8 if is_rage else 2.5
	if _attack_timer >= interval:
		_attack_timer = 0.0
		_execute_attack()


func _execute_attack() -> void:
	if is_rage:
		_fire_ring(16)
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(self) and is_inside_tree():
			_fire_straight_shots(5)
	else:
		_fire_ring(8)
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(self) and is_inside_tree():
			_fire_straight_shots(3)


func _fire_straight_shots(count: int) -> void:
	var player = _get_player()
	if not is_instance_valid(player):
		return
	var bullet_root = _get_bullet_root()
	if not bullet_root or not is_instance_valid(bullet_root):
		return
	var base_dir := global_position.direction_to(player.global_position)
	for i in range(count):
		var offset := randf_range(-0.12, 0.12)
		var final_dir := base_dir.rotated(offset)
		_spawn_bullet(final_dir, bullet_speed * 1.5, bullet_damage * 2.0)


func _enter_rage_mode() -> void:
	super._enter_rage_mode()
	_base_tint = Color(1.0, 0.13, 0.13)
	_update_shader_params()


func _die() -> void:
	SoundManager.play_sfx("boss_death")
	_spawn_death_effect()
	_spawn_wreck()
	_spawn_death_rewards()
	if game_manager and is_instance_valid(game_manager):
		game_manager.spawn_boss_loot(self)
		game_manager.try_drop_equipment(self)
	enemy_dead.emit(self, "boss")
	queue_free()
