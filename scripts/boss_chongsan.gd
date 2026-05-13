extends BossBase

## 冲三杀手。第1章第5关BOSS。
## Phase 1 (>50% HP): 追踪玩家 + 三连扇形弹幕
## Phase 2 (<50% HP 狂暴): 加速追踪 + 5连扇形弹幕 + 突进冲刺

enum State { TRACKING, RUSH_PREPARE, RUSHING, RUSH_COOLDOWN }

var _boss_state: State = State.TRACKING

var _rush_start_pos: Vector2 = Vector2.ZERO
var _rush_target_pos: Vector2 = Vector2.ZERO
var _rush_direction: Vector2 = Vector2.ZERO
var _rush_timer: float = 0.0
var _rush_speed: float = 800.0
var _rush_cooldown: float = 0.0
var _rush_damage_dealt: bool = false

func _ready() -> void:
	_base_tint = Color(0.0, 0.8, 0.8)
	_visual_scale = 1.2
	_icon_id = "boss_chongsan"
	tonnage = "boss"
	_hp_bar_max_width = 102.0
	_hit_flash_intensity = 3.0
	_dmg_number_font_size_normal = 20
	_dmg_number_font_size_crit = 28
	_dmg_number_offset_x_range = 40.0
	_dmg_number_offset_y = -60.0
	_dmg_number_anim_offset = 80.0
	_dmg_number_anim_duration = 0.8
	_dmg_number_color_normal = Color(0.3, 1.0, 1.0)
	_dmg_number_color_crit = Color(1.0, 0.8, 0.0)
	_death_particle_color = Color(0.0, 0.8, 0.8, 1.0)
	_death_particle_count = 40
	_death_particle_lifetime = 1.0
	_death_particle_velocity_min = 100.0
	_death_particle_velocity_max = 300.0
	_death_particle_scale_min = 5.0
	_death_particle_scale_max = 15.0
	_death_burst_count = 5
	super._ready()


func setup_from_entry(entry: BossEntry) -> void:
	super.setup_from_entry(entry)
	_rush_cooldown = 3.0


func _process_movement(delta: float) -> void:
	var player = _get_player()
	if not is_instance_valid(player):
		return

	match _boss_state:
		State.TRACKING:
			var speed = move_speed * 1.3 if is_rage else move_speed
			var direction := global_position.direction_to(player.global_position)
			global_position += direction * speed * delta

		State.RUSH_PREPARE:
			_rush_timer -= delta
			if _rush_timer <= 0.0:
				_rush_start_pos = global_position
				_rush_direction = _rush_target_pos.direction_to(player.global_position)
				_rush_timer = 0.5
				_rush_damage_dealt = false
				_boss_state = State.RUSHING

		State.RUSHING:
			_rush_timer -= delta
			var rush_spd = _rush_speed * (1.5 if is_rage else 1.0)
			global_position += _rush_direction * rush_spd * delta
			_check_rush_damage()
			if _rush_timer <= 0.0:
				_boss_state = State.RUSH_COOLDOWN

		State.RUSH_COOLDOWN:
			_rush_timer -= delta
			if _rush_timer <= 0.0:
				_boss_state = State.TRACKING


func _process_combat(delta: float) -> void:
	_process_movement(delta)
	_process_contact_damage(_get_player())
	_process_rage_check()

	if _boss_state == State.TRACKING:
		_process_attack_pattern(delta)

	if is_rage:
		_process_rush_trigger(delta)


func _process_rush_trigger(delta: float) -> void:
	if _boss_state != State.TRACKING:
		return
	_rush_cooldown -= delta
	if _rush_cooldown <= 0.0:
		var player = _get_player()
		if is_instance_valid(player):
			var dist := global_position.distance_to(player.global_position)
			if dist < 350.0:
				_rush_target_pos = global_position
				_rush_timer = 0.4
				_boss_state = State.RUSH_PREPARE
				_rush_cooldown = 2.5


func _check_rush_damage() -> void:
	if _rush_damage_dealt:
		return
	var player = _get_player()
	if not is_instance_valid(player):
		return
	var dist := global_position.distance_to(player.global_position)
	if dist < 60.0:
		if player.has_method("on_player_take_damage"):
			player.on_player_take_damage(damage * 1.5)
		_rush_damage_dealt = true


func _execute_attack_pattern() -> void:
	if is_rage:
		_fire_spread(5, 12.0)
		await get_tree().create_timer(0.12).timeout
		if is_instance_valid(self) and is_inside_tree():
			_fire_aimed_shot(2, 0.1)
	else:
		_fire_spread(3, 15.0)
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(self) and is_inside_tree():
			_fire_aimed_shot(1, 0.0)


func _enter_rage_mode() -> void:
	super._enter_rage_mode()
	_base_tint = Color(1.0, 0.5, 0.0)
	_update_shader_params()
	_rush_cooldown = 1.0


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
