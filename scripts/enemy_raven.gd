extends EnemyBase

const StageData = preload("res://resources/stage_data.gd")

var explosion_range: float = 100.0
var explosion_damage: float = 25.0
var explosion_windup: float = 0.5

var current_state: String = "chase"
var windup_timer: float = 0.0
var windup_flash_timer: float = 0.0
var windup_flash_visible: bool = true

func _ready() -> void:
	_base_tint = Color(1.0, 0.5, 0.0)
	super()
	_icon_id = "enemy_raven"
	_chapter_stats_key = "raven"
	tonnage = "frigate"

func _apply_chapter_stats() -> void:
	var cid: int = _chapter_id_override if _chapter_id_override > 0 else (game_manager.current_chapter_id if game_manager else 0)
	var raven_stats: StageData.ToncalStats = StageData.get_chapter_stats(cid, "raven")
	var strength_mult: float = game_manager.current_stage.strength_mult if game_manager and game_manager.current_stage else 1.0
	var speed_mult: float = 1.0
	if game_manager and game_manager.difficulty_scaler and game_manager.difficulty_scaler.has_method("get_strength_mult"):
		strength_mult *= game_manager.difficulty_scaler.get_strength_mult()
		speed_mult = game_manager.difficulty_scaler.get_speed_mult()
	explosion_damage = raven_stats.explosion_damage * strength_mult
	move_speed = raven_stats.speed * speed_mult

func _update_movement(delta: float) -> void:
	var player = _get_player()
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	match current_state:
		"chase":
			var dir = global_position.direction_to(player.global_position).normalized()
			velocity = dir * move_speed
			move_and_slide()
			var dist = global_position.distance_to(player.global_position)
			if dist < 30.0:
				current_state = "windup"
				velocity = Vector2.ZERO
				windup_timer = 0.0
				windup_flash_timer = 0.0
				windup_flash_visible = true
		"windup":
			velocity = Vector2.ZERO
			move_and_slide()
			windup_timer += delta
			windup_flash_timer += delta
			if windup_flash_timer >= 0.1:
				windup_flash_timer = 0.0
				windup_flash_visible = not windup_flash_visible
				queue_redraw()
			if windup_timer >= explosion_windup:
				_do_explosion()

func _do_explosion() -> void:
	SoundManager.play_sfx("enemy_death")
	var player = _get_player()
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= explosion_range:
			if player.has_method("on_player_take_damage"):
				player.on_player_take_damage(explosion_damage)

	var parent = get_parent()
	if parent:
		var explosion = CPUParticles2D.new()
		explosion.amount = 30
		explosion.lifetime = 0.5
		explosion.one_shot = true
		explosion.emission_shape = 0
		explosion.direction = Vector2(0, -1)
		explosion.spread = 180.0
		explosion.initial_velocity_min = 150.0
		explosion.initial_velocity_max = 300.0
		explosion.scale_amount_min = 4.0
		explosion.scale_amount_max = 10.0
		explosion.color = Color(1.0, 0.4, 0.1, 1.0)
		explosion.position = global_position
		parent.call_deferred("add_child", explosion)
		explosion.emitting = true
		explosion.finished.connect(explosion.queue_free)

	queue_free()

func _die() -> void:
	SoundManager.play_sfx("enemy_death")
	enemy_dead.emit(self, "raven")
	if game_manager and is_instance_valid(game_manager):
		game_manager.try_drop_equipment(self)
	queue_free()

func _get_enemy_type() -> String:
	return "raven"

func is_windup_blinking() -> bool:
	return current_state == "windup"

func is_windup_state() -> bool:
	return current_state == "windup"

func get_windup_blink_visible() -> bool:
	return windup_flash_visible

func get_locked_bracket_color() -> Color:
	if current_state == "windup":
		return Color(1.0, 0.5, 0.0)
	return Color(1.0, 0.2, 0.2)
