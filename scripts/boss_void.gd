extends EnemyBase

const _SCENE_BOSS_BULLET: PackedScene = preload("res://scenes/BossBullet.tscn")
const _SCENE_EXP_ORB: PackedScene = preload("res://scenes/ExpOrb.tscn")

var _loot_tonnage_chapter: int = 1
var collision_damage: float = 15.0
var contact_cooldown: float = 0.5
var contact_timer: float = 0.0

var fire_interval_normal: float = 1.5
var fire_interval_rage: float = 1.0
var fire_timer: float = 0.0
var bullet_speed: float = 400.0
var bullet_damage: float = 10.0
var is_rage: bool = false

var hp_bar_bg: ColorRect

func _ready() -> void:
	# Boss visual — must be set before super so set_enemy_icon/_init_lock use correct values
	_base_tint = Color(0.5, 0.0, 0.5)
	_visual_scale = 1.2
	_icon_id = "boss_void"
	tonnage = "battlecruiser"

	# Boss damage number config (larger, more dramatic)
	_dmg_number_font_size_normal = 20
	_dmg_number_font_size_crit = 28
	_dmg_number_offset_x_range = 40.0
	_dmg_number_offset_y = -60.0
	_dmg_number_anim_offset = 80.0
	_dmg_number_anim_duration = 0.8
	_dmg_number_color_normal = Color(1.0, 0.3, 0.3)
	_dmg_number_color_crit = Color(1.0, 0.8, 0.0)

	# Boss death effect — 5 bursts scattered around death position
	_death_particle_color = Color(0.5, 0.0, 0.5, 1.0)
	_death_particle_count = 40
	_death_particle_lifetime = 1.0
	_death_particle_velocity_min = 100.0
	_death_particle_velocity_max = 300.0
	_death_particle_scale_min = 5.0
	_death_particle_scale_max = 15.0
	_death_burst_count = 5

	# Boss hit flash — brighter
	_hit_flash_intensity = 3.0

	# Boss HP bar — wider
	_hp_bar_max_width = 102.0

	super._ready()

	hp_bar_bg = $HPBarBg

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func _process_combat(delta: float) -> void:
	var player = _get_player()
	if not is_instance_valid(player):
		return

	contact_timer += delta
	if contact_timer >= contact_cooldown:
		contact_timer = 0.0
		if global_position.distance_to(player.global_position) < 50.0:
			if player.has_method("on_player_take_damage"):
				player.on_player_take_damage(collision_damage)

	if hp / max_hp <= 0.6 and not is_rage:
		_enter_rage_mode()

	fire_timer += delta
	var interval = fire_interval_rage if is_rage else fire_interval_normal
	if fire_timer >= interval:
		fire_timer = 0.0
		_fire_spread()

func _enter_rage_mode() -> void:
	is_rage = true
	move_speed = 120.0
	_base_tint = Color(1.0, 0.2, 0.2)
	_update_shader_params()

func _fire_spread() -> void:
	var player = _get_player()
	if not is_instance_valid(player):
		return

	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return

	var base_angle = global_position.angle_to_point(player.global_position)
	var bullet_count = 5 if is_rage else 3
	var angle_step = deg_to_rad(12.0) if is_rage else deg_to_rad(15.0)
	var total_spread = angle_step * (bullet_count - 1)

	for i in range(bullet_count):
		var angle = base_angle - total_spread / 2.0 + angle_step * i
		var dir = Vector2.from_angle(angle)

		var bullet = _SCENE_BOSS_BULLET.instantiate()
		bullet_root.add_child(bullet)
		bullet.global_position = global_position
		bullet.setup(dir, bullet_damage, bullet_speed, game_manager, player)

func _get_loot_tonnage_chapter() -> int:
	return _loot_tonnage_chapter

func setup_boss(gm: Node2D, b_hp: float = 500.0, b_damage: float = 15.0, b_speed: float = 80.0, b_shield: float = 167.0, tonnage_chapter: int = 1) -> void:
	_loot_tonnage_chapter = tonnage_chapter
	game_manager = gm
	max_hp = b_hp
	hp = b_hp
	enemy_shield_max = b_shield
	enemy_shield = b_shield
	collision_damage = b_damage
	move_speed = b_speed
	is_rage = false
	fire_timer = 0.0
	contact_timer = 0.0
	# Icon is set via _chapter_icon_override in setup_enemy pattern
	_chapter_icon_override = "boss_void"
	_apply_chapter_icon()

func _on_death_rewards() -> void:
	SoundManager.play_sfx("boss_death")
	var parent = game_manager.get("exp_orb_root")
	if parent:
		for i in range(10):
			var angle = TAU * i / 10.0
			var orb = _SCENE_EXP_ORB.instantiate()
			orb.set_game_manager(game_manager)
			orb.global_position = global_position + Vector2.from_angle(angle) * 60.0
			parent.call_deferred("add_child", orb)

func _die() -> void:
	_spawn_death_effect()
	_on_death_rewards()
	if game_manager and is_instance_valid(game_manager):
		game_manager.spawn_boss_loot(self)
		game_manager.try_drop_equipment(self)
	enemy_dead.emit(self, "boss")
	queue_free()

func _get_enemy_type() -> String:
	return "boss"
