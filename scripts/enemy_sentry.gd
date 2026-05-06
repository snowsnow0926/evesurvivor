extends EnemyBase

const StageData = preload("res://resources/stage_data.gd")

const _SCENE_SENTRY_BULLET: PackedScene = preload("res://scenes/SentryBullet.tscn")

var fire_interval: float = 1.2
var fire_timer: float = 0.0
var bullet_speed: float = 400.0
var bullet_damage: float = 8.0
var detection_range: float = 700.0
var preferred_distance: float = 350.0
var fire_range: float = 500.0
var contact_cooldown: float = 0.5
var contact_timer: float = 0.0
var current_state: String = "idle"

func _ready() -> void:
	_base_tint = Color(0.5, 0.2, 1.0)
	super()
	_icon_id = "enemy_sentry"
	_chapter_stats_key = "sentry"
	tonnage = "cruiser"
	_death_particle_color = Color(0.5, 0.2, 1.0, 1.0)

func _apply_chapter_stats() -> void:
	var cid: int = _chapter_id_override if _chapter_id_override > 0 else (game_manager.current_chapter_id if game_manager else 0)
	var sentry_stats := StageData.get_chapter_stats(cid, "sentry")
	var level_bonus: float = 1.0 + 0.3 * (game_manager.player_level - 1) if game_manager else 1.0
	var final_strength: float = (game_manager.current_stage.strength_mult * level_bonus) if game_manager and game_manager.current_stage else 1.0
	bullet_damage = sentry_stats.damage * final_strength

func _process_combat(delta: float) -> void:
	var player = _get_player()
	if not is_instance_valid(player):
		return

	var dist = global_position.distance_to(player.global_position)

	contact_timer += delta
	if contact_timer >= contact_cooldown:
		contact_timer = 0.0
		if dist < 64.0:
			if player.has_method("on_player_take_damage"):
				player.on_player_take_damage(damage)

	if current_state != "idle" and dist <= fire_range:
		fire_timer += delta
		if fire_timer >= fire_interval:
			fire_timer = 0.0
			_fire_at_player()

func _update_movement(_delta: float) -> void:
	var player = _get_player()
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dist = global_position.distance_to(player.global_position)

	if dist > detection_range:
		velocity = Vector2.ZERO
		current_state = "idle"
	elif dist < preferred_distance - 20.0:
		var dir = global_position.direction_to(player.global_position).normalized()
		velocity = -dir * move_speed
		current_state = "retreat"
	elif dist > preferred_distance + 20.0:
		var dir = global_position.direction_to(player.global_position).normalized()
		velocity = dir * move_speed
		current_state = "approach"
	else:
		velocity = Vector2.ZERO
		current_state = "hold"

	move_and_slide()

func _fire_at_player() -> void:
	if not _is_locked:
		return
	var player = _get_player()
	if not is_instance_valid(player):
		return
	if global_position.distance_to(player.global_position) > fire_range:
		return

	trigger_attack_flash()

	var bullet_root = game_manager.get("bullet_root")
	if not bullet_root or not is_instance_valid(bullet_root):
		return

	var bullet = _SCENE_SENTRY_BULLET.instantiate()
	bullet_root.add_child(bullet)
	bullet.global_position = global_position

	var dir = global_position.direction_to(player.global_position).normalized()
	bullet.setup(dir, bullet_damage, bullet_speed, game_manager, player)

func _die() -> void:
	SoundManager.play_sfx("enemy_death")
	enemy_dead.emit(self, "sentry")
	if game_manager and is_instance_valid(game_manager):
		game_manager.try_drop_equipment(self)
	queue_free()

func _get_enemy_type() -> String:
	return "sentry"
