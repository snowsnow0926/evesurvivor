class_name PlayerStats
extends Resource

## Single source of truth for all player combat attributes.
## Player and GameManager both reference this instance.
## All mutation goes through setters that emit signals for UI auto-refresh.

signal hp_changed(current: int, maximum: int)
signal shield_changed(current: float, maximum: float)
signal stats_changed()

# === Health & Shield ===
@export var hp: int = 100:
	set(v):
		hp = clampi(v, 0, max_hp)
		hp_changed.emit(hp, max_hp)
		stats_changed.emit()

@export var max_hp: int = 100:
	set(v):
		max_hp = maxi(v, 1)
		hp_changed.emit(hp, max_hp)
		stats_changed.emit()

@export var shield: float = 50.0:
	set(v):
		shield = clampf(v, 0.0, shield_max)
		shield_changed.emit(shield, shield_max)
		stats_changed.emit()

@export var shield_max: float = 50.0:
	set(v):
		shield_max = maxf(v, 0.0)
		shield_changed.emit(shield, shield_max)
		stats_changed.emit()

@export var shield_regen: float = 4.0
@export var shield_regen_timer: float = 0.0
@export var hp_regen: float = 0.0
@export var hp_regen_timer: float = 0.0

# === Movement & Survival ===
@export var move_speed: float = 320.0
@export var dodge: float = 0.1
@export var lifesteal: float = 0.0
@export var lifesteal_timer: float = 0.0

# === Crit ===
@export var crit_rate: float = 0.05
@export var crit_mult: float = 1.5

# === Universal Weapon ===
@export var damage: float = 15.0
@export var xp_boost: float = 1.0

# === Missile Tree ===
@export var missile_speed: float = 600.0
@export var missile_range: float = 500.0
@export var missile_splash_radius: float = 0.0
@export var missile_splash_count: int = 0
@export var spread_count: int = 1
@export var spread_angle: float = 6.0

# === Cannon Tree ===
@export var cannon_fire_interval: float = 1.2
@export var cannon_damage: float = 25.0
@export var cannon_pierce_count: int = 1
@export var cannon_explode_chance: float = 0.0
@export var cannon_bloodthirst: int = 0
@export var cannon_rush_level: int = 0
@export var cannon_vengeance_level: int = 0

# === Railgun Tree ===
@export var railgun_damage: float = 30.0
@export var railgun_speed: float = 1000.0
@export var railgun_range: float = 400.0
@export var railgun_fire_interval: float = 0.6
@export var railgun_crit_bonus: float = 0.0
@export var railgun_multi_count: int = 1

# === Laser Tree ===
@export var laser_damage: float = 12.0
@export var laser_duration: float = 2.0
@export var laser_width: float = 16.0
@export var laser_fire_interval: float = 2.5
@export var laser_shield_mult: float = 1.0

# === Passive Skill Levels ===
@export var silent_hunter_level: int = 0

# === Transient State (not persisted) ===
var is_moving: bool = false
var is_stationary: bool = false
var is_injured: bool = false
var injured_timer: float = 0.0
const INJURED_DURATION: float = 2.0

func _init() -> void:
	hp_changed.connect(_on_hp_changed)
	shield_changed.connect(_on_shield_changed)

func _on_hp_changed(_current: int, _maximum: int) -> void:
	pass

func _on_shield_changed(_current: float, _maximum: float) -> void:
	pass

func reset() -> void:
	var mh = max_hp
	var sm = shield_max
	var sr = shield_regen
	var hr = hp_regen
	var ms = move_speed
	var d = dodge
	var cr = crit_rate
	var cm = crit_mult
	var ls = lifesteal
	var xb = xp_boost

	var new_stats := PlayerStats.new()
	new_stats.max_hp = mh
	new_stats.shield_max = sm
	new_stats.shield_regen = sr
	new_stats.hp_regen = hr
	new_stats.move_speed = ms
	new_stats.dodge = d
	new_stats.crit_rate = cr
	new_stats.crit_mult = cm
	new_stats.lifesteal = ls
	new_stats.xp_boost = xb

	self._copy_from(new_stats)

func full_reset() -> void:
	var new_stats := PlayerStats.new()
	self._copy_from(new_stats)
	damage = 15.0
	xp_boost = 1.0
	missile_speed = 600.0
	missile_range = 500.0
	missile_splash_radius = 0.0
	missile_splash_count = 0
	spread_count = 1
	spread_angle = 6.0
	cannon_fire_interval = 1.2
	cannon_damage = 25.0
	cannon_pierce_count = 1
	cannon_explode_chance = 0.0
	cannon_bloodthirst = 0
	cannon_rush_level = 0
	cannon_vengeance_level = 0
	railgun_damage = 30.0
	railgun_speed = 1000.0
	railgun_range = 400.0
	railgun_fire_interval = 0.6
	railgun_crit_bonus = 0.0
	railgun_multi_count = 1
	laser_damage = 12.0
	laser_duration = 2.0
	laser_width = 16.0
	laser_fire_interval = 2.5
	laser_shield_mult = 1.0
	silent_hunter_level = 0

func _copy_from(other: PlayerStats) -> void:
	max_hp = other.max_hp
	shield_max = other.shield_max
	shield_regen = other.shield_regen
	hp_regen = other.hp_regen
	move_speed = other.move_speed
	dodge = other.dodge
	crit_rate = other.crit_rate
	crit_mult = other.crit_mult
	lifesteal = other.lifesteal
	xp_boost = other.xp_boost

func apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"damage":
			damage *= 1.2
		"shield_max":
			shield_max += 30.0
			shield = shield_max
		"fire_coverage":
			spread_count += 1
		"shield_regen":
			shield_regen *= 1.5
		"silent_hunter":
			silent_hunter_level += 1
		"precision_kill":
			missile_range += 100.0
		"cannon_bloodthirst":
			cannon_bloodthirst += 1
		"cannon_rush":
			cannon_rush_level += 1
		"cannon_vengeance":
			cannon_vengeance_level += 1
		"railgun_damage":
			railgun_damage *= 1.2
		"railgun_crit":
			railgun_crit_bonus += 0.1
		"railgun_multi":
			railgun_multi_count += 1
		"laser_duration":
			laser_duration *= 1.2
		"laser_width":
			laser_width *= 1.2
		"laser_shield":
			laser_shield_mult += 0.2
	stats_changed.emit()

func update_regen(delta: float) -> void:
	shield_regen_timer += delta
	if shield_regen_timer >= 1.0:
		shield_regen_timer = 0.0
		shield = minf(shield + shield_regen, shield_max)

	if hp_regen > 0.0:
		hp_regen_timer += delta
		if hp_regen_timer >= 1.0:
			hp_regen_timer = 0.0
			hp = mini(hp + int(hp_regen), max_hp)

	if lifesteal > 0.0:
		lifesteal_timer += delta
		if lifesteal_timer >= 1.0:
			lifesteal_timer = 0.0
			hp = mini(hp + int(lifesteal), max_hp)

func get_fire_interval_missile(base_interval: float) -> float:
	var mult = 1.0
	if is_stationary and silent_hunter_level > 0:
		mult = pow(0.85, float(silent_hunter_level))
	if is_moving and cannon_rush_level > 0:
		mult *= (1.0 - 0.15 * float(cannon_rush_level))
	return base_interval * mult

func get_fire_interval_cannon(base_interval: float) -> float:
	var interval = base_interval
	if is_moving and cannon_rush_level > 0:
		interval *= (1.0 - 0.15 * float(cannon_rush_level))
	if is_injured and cannon_vengeance_level > 0:
		interval *= (1.0 - 0.15 * float(cannon_vengeance_level))
	return interval

func take_damage(amount: float, crit: bool) -> bool:
	if randf() < dodge:
		return false
	var final_damage = amount
	if crit:
		final_damage *= crit_mult
	if shield > 0:
		var shield_dmg = minf(shield, final_damage)
		shield -= shield_dmg
		final_damage -= shield_dmg
	hp -= int(final_damage)
	is_injured = true
	injured_timer = INJURED_DURATION
	return true
