extends EnemyBase

var attack_cooldown: float = 0.5
var attack_timer: float = 0.0
var can_attack: bool = true

func _ready() -> void:
	_icon_id = "enemy_melee"
	_base_tint = Color(1.0, 0.2, 0.2)
	tonnage = "destroyer"
	super()
	_death_particle_color = Color(1.0, 0.2, 0.2, 1.0)

func _apply_chapter_icon() -> void:
	var cid: int = _chapter_id_override if _chapter_id_override > 0 else (game_manager.current_chapter_id if game_manager else 0)
	match cid:
		2:
			var entry: ShipIconGenerator.IconEntry = ShipIconGenerator.get_entry(ShipIconGenerator.Category.ENEMY, "enemy_melee_cruiser")
			if entry != null:
				_icon_tex = entry.get_texture()
				if ship_sprite:
					ship_sprite.texture = _icon_tex
					ship_sprite.material = null
					ship_sprite.visible = true
				if polygon:
					polygon.visible = false
		3:
			var entry2: ShipIconGenerator.IconEntry = ShipIconGenerator.get_entry(ShipIconGenerator.Category.ENEMY, "enemy_melee_battlecruiser")
			if entry2 != null:
				_icon_tex = entry2.get_texture()
				if ship_sprite:
					ship_sprite.texture = _icon_tex
					ship_sprite.material = null
					ship_sprite.visible = true
				if polygon:
					polygon.visible = false
		4:
			var entry3: ShipIconGenerator.IconEntry = ShipIconGenerator.get_entry(ShipIconGenerator.Category.ENEMY, "enemy_melee_battleship")
			if entry3 != null:
				_icon_tex = entry3.get_texture()
				if ship_sprite:
					ship_sprite.texture = _icon_tex
					ship_sprite.material = null
					ship_sprite.visible = true
				if polygon:
					polygon.visible = false
		5:
			var entry4: ShipIconGenerator.IconEntry = ShipIconGenerator.get_entry(ShipIconGenerator.Category.ENEMY, "enemy_melee_dreadnought")
			if entry4 != null:
				_icon_tex = entry4.get_texture()
				if ship_sprite:
					ship_sprite.texture = _icon_tex
					ship_sprite.material = null
					ship_sprite.visible = true
				if polygon:
					polygon.visible = false

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func _process_combat(_delta: float) -> void:
	if not can_attack:
		attack_timer += _delta
		if attack_timer >= attack_cooldown:
			attack_timer = 0.0
			can_attack = true
		return

	var player = _get_player()
	if not is_instance_valid(player):
		return

	var dist = global_position.distance_to(player.global_position)
	if dist < 64.0:
		can_attack = false
		attack_timer = 0.0
		trigger_attack_flash()
		if player.has_method("on_player_take_damage"):
			player.on_player_take_damage(damage)

func _update_movement(_delta: float) -> void:
	var player = _get_player()
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction = global_position.direction_to(player.global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

func _get_enemy_type() -> String:
	return "melee"
