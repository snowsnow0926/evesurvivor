extends EnemyBase

var _loot_tonnage_chapter: int = 1
var base_move_speed: float = 80.0
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
	_base_tint = Color(0.5, 0.0, 0.5)
	super._ready()
	polygon = $Polygon2D
	ship_sprite = $ShipSprite
	hp_bar = $HPBar
	hp_bar_bg = $HPBarBg
	if polygon:
		polygon.rotation = PI / 2
	scale = Vector2(3.0, 3.0)
	_update_shader_params()
	_death_particle_color = Color(0.5, 0.0, 0.5, 1.0)
	_init_lock()
	setup_icon()

func setup_icon() -> void:
	var tex: Texture2D = ShipIconGenerator.get_texture(ShipIconGenerator.Category.SHIP, "npcbattleCruiser")
	if tex != null:
		_icon_tex = tex
		ship_sprite.texture = tex
		ship_sprite.material = _tint_mat
		ship_sprite.visible = true
		ship_sprite.offset = Vector2.ZERO
		polygon.visible = false
		_update_shader_params()
	else:
		ship_sprite.visible = false
		polygon.visible = true

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

	var bullet_path = "res://scenes/BossBullet.tscn"
	if not ResourceLoader.exists(bullet_path):
		return

	var base_angle = global_position.angle_to_point(player.global_position)
	var bullet_count = 5 if is_rage else 3
	var angle_step = deg_to_rad(12.0) if is_rage else deg_to_rad(15.0)
	var total_spread = angle_step * (bullet_count - 1)

	for i in range(bullet_count):
		var angle = base_angle - total_spread / 2.0 + angle_step * i
		var dir = Vector2.from_angle(angle)

		var bullet_scene = load(bullet_path)
		var bullet = bullet_scene.instantiate()
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
	base_move_speed = b_speed
	move_speed = b_speed
	is_rage = false
	fire_timer = 0.0
	contact_timer = 0.0
	_setup_tonnage_icon(tonnage_chapter)

func _setup_tonnage_icon(cid: int) -> void:
	var icon_name := "npcbattleCruiser"
	match cid:
		1: icon_name = "npcdestroyer"
		2: icon_name = "npccruiser"
		3: icon_name = "npcbattleCruiser"
		4: icon_name = "npcbattleship"
		5: icon_name = "npcdreadnought"
	var tex: Texture2D = ShipIconGenerator.get_texture(ShipIconGenerator.Category.SHIP, icon_name)
	if tex != null:
		_icon_tex = tex
		ship_sprite.texture = tex
		ship_sprite.material = _tint_mat
		ship_sprite.visible = true
		ship_sprite.offset = Vector2.ZERO
		polygon.visible = false
		_update_shader_params()
	else:
		ship_sprite.visible = false
		polygon.visible = true

func _spawn_damage_number(amount: float, is_crit: bool) -> void:
	var parent = get_parent()
	if not parent:
		return

	var label = Label.new()
	label.text = str(int(amount)) + ("!" if is_crit else "")
	label.add_theme_font_size_override("font_size", 28 if is_crit else 20)
	if is_crit:
		label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	else:
		label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

	label.position = global_position + Vector2(randf_range(-40, 40), -60)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.call_deferred("add_child", label)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 80, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)

	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.9
	timer.timeout.connect(label.queue_free)
	parent.call_deferred("add_child", timer)
	timer.call_deferred("start")

func _update_hp_bar() -> void:
	if hp_bar:
		var ratio = clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)
		hp_bar.scale.x = ratio
		if hp_bar_bg:
			hp_bar.position.x = -51.0 * ratio

func _start_hit_flash() -> void:
	var target: Node = ship_sprite if ship_sprite and ship_sprite.visible else polygon
	if not target:
		return
	var original_color = target.modulate if target.modulate is Color else Color.WHITE
	target.modulate = Color(3.0, 3.0, 3.0)
	var tween = create_tween()
	tween.tween_property(target, "modulate", original_color, 0.15)

func _spawn_death_effect() -> void:
	var parent = get_parent()
	if not parent:
		return

	for _i in range(5):
		var offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
		var particles = CPUParticles2D.new()
		particles.amount = 40
		particles.lifetime = 1.0
		particles.one_shot = true
		particles.emission_shape = 0
		particles.direction = Vector2(0, -1)
		particles.spread = 180.0
		particles.initial_velocity_min = 100.0
		particles.initial_velocity_max = 300.0
		particles.scale_amount_min = 5.0
		particles.scale_amount_max = 15.0
		particles.color = _death_particle_color
		particles.position = global_position + offset
		parent.call_deferred("add_child", particles)
		particles.emitting = true
		particles.finished.connect(particles.queue_free)

func _spawn_rewards() -> void:
	if not is_instance_valid(game_manager):
		return

	var parent = game_manager.get("exp_orb_root")
	if parent:
		for i in range(10):
			var angle = TAU * i / 10.0
			var orb_scene = load("res://scenes/ExpOrb.tscn")
			if orb_scene:
				var orb = orb_scene.instantiate()
				orb.set_game_manager(game_manager)
				orb.global_position = global_position + Vector2.from_angle(angle) * 60.0
				parent.call_deferred("add_child", orb)

func _die() -> void:
	SoundManager.play_sfx("boss_death")
	_spawn_death_effect()
	_spawn_rewards()
	if game_manager and is_instance_valid(game_manager):
		game_manager.spawn_boss_loot(self)
	enemy_dead.emit(self, "boss")
	queue_free()

func _get_enemy_type() -> String:
	return "boss"
