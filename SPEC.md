# EVE Survivor — Project Specification & Optimization Plan

> Last Updated: 2026-05-01
> Godot Version: 4.6
> Language: GDScript

---

## 1. Project Overview

**Project Name**: EVE Survivor (EVE同人幸存者游戏)
**Type**: 2D top-down survivor-like roguelike game inspired by EVE Online
**Core Loop**: Fight enemies in arena → Level up with upgrades → Return to base → Upgrade ships/equipment → Repeat
**Resolution**: 1920x1080, canvas_items stretch mode

---

## 2. Architecture Overview

### 2.1 Scene Hierarchy

```
MainMenu.tscn
  └─ main_menu.gd

CharacterCreate.tscn
  └─ character_create.gd

RaceSelect.tscn
  └─ race_select.gd

BaseScene.tscn (基地主界面)
  ├─ base_scene.gd (main controller)
  ├─ repair_station.gd
  ├─ crafting_table.gd
  ├─ ship_storage.gd
  ├─ shop_ui.gd
  ├─ warehouse_ui.gd
  ├─ shipyard_ui.gd
  └─ base_pause_menu.gd

GameScene.tscn (战斗场景)
  ├─ game_scene.gd (scene controller)
  ├─ game_manager.gd (combat manager)
  ├─ parallax_starfield.gd
  ├─ HUD.tscn (hud.gd)
  ├─ UpgradeMenu.tscn (upgrade_menu.gd)
  ├─ PauseMenu.tscn (pause_menu.gd)
  └─ BossWarning.tscn (boss_warning.gd)

SettlementScene.tscn
  └─ settlement_scene.gd
```

### 2.2 Autoloads

| Autoload | File | Purpose |
|----------|------|---------|
| **GameState** | `game_state.gd` | Global game state, currency, equipment, ship selection |
| **SoundManager** | `sound_manager.gd` | Music and SFX playback |
| **GameBalance** | `game_balance_loader.gd` | Loads `game_balance.json` for game tuning |

### 2.3 Data Resources

| Resource | File | Purpose |
|----------|------|---------|
| ShipData | `ship_data.gd` | 6 ship tiers (Frigate → Titan) |
| WeaponData | `weapon_data.gd` | 20 weapon types (4 categories × 5 tiers) |
| EquipmentData | `equipment_data.gd` | Quality/enum helpers |
| ShopItemData | `shop_data.gd` | 24 shop items (16 weapons + 8 armors) |
| RaceData | `race_data.gd` | 4 playable races with talents |

### 2.4 Enemy Types

| Enemy | Script | Behavior |
|-------|--------|----------|
| Melee | `enemy_melee.gd` | Chases player, contact damage |
| Sentry | `enemy_sentry.gd` | Maintains distance, ranged shots |
| Raven | `enemy_raven.gd` | Suicide bomber, explosion on contact |
| Boss (Void) | `boss_void.gd` | HP-based rage mode, spread bullets |

### 2.5 Projectile Types

| Weapon | Script |
|--------|--------|
| Missile | `missile.gd` (homing, splash) |
| Cannon | `cannon_bullet.gd` (piercing) |
| Railgun | `railgun_bullet.gd` (high-crit burst) |
| Laser | `laser_beam.gd` (continuous beam) |

---

## 3. Current Issues & Optimization Plan

### 3.1 Critical Issues

#### 🔴 P1: No Save/Load System
- **Status**: Missing
- **Impact**: All progress lost on restart
- **Fix**: Implement `GameState.save()` and `GameState.load()` using Godot `ConfigFile`

#### 🔴 P2: Massive State Duplication (game_manager ↔ player)
- **Status**: `game_manager.gd` and `player.gd` each maintain ~35 identical weapon/stat variables
- **Impact**: Error-prone manual sync via `sync_from_game_manager()`
- **Fix**: Extract all combat stats to a `PlayerStats` Resource class

#### 🔴 P3: Enemy Script Code Duplication
- **Status**: `_spawn_damage_number()`, `_spawn_death_effect()`, `_start_hit_flash()` duplicated across all 4 enemy scripts
- **Impact**: ~200 lines of repeated code, hard to maintain
- **Fix**: Create `EnemyBase.gd` base class

#### 🔴 P4: Resource Instance Recreated Every Call
- **Status**: `ShipData.get_ship()`, `WeaponData.get_weapon()` create new instances on each call
- **Impact**: Unnecessary memory churn
- **Fix**: Add static caching

### 3.2 Medium Priority

#### 🟡 P5: Debug Print Statements Everywhere
- **Status**: ~50+ `print()` statements across scripts
- **Fix**: Add `const DEBUG := true` flag, replace with `_debug()` helpers

#### 🟡 P6: God Class (game_manager.gd)
- **Status**: 771 lines handling combat, spawning, upgrades, difficulty, rewards
- **Fix**: Eventually split into `SpawnManager`, `UpgradeSystem`, `DifficultyScaler`

### 3.3 Low Priority

#### 🟢 P7: Sound Assets Missing
- **Status**: All SFX paths in `sound_manager.gd` are empty strings
- **Fix**: Either implement audio or remove dead code

#### 🟢 P8: game_balance.json May Not Exist
- **Status**: Config file may be missing
- **Fix**: Create the JSON file with default values

#### 🟢 P9: Magic Numbers Scattered
- **Fix**: Extract named constants

#### 🟢 P10: Inconsistent Naming
- **Fix**: Standardize on English or Chinese consistently

---

## 4. Optimization Roadmap

| Phase | Task | Priority | Status |
|-------|------|----------|--------|
| 1 | Save/Load System | P1 | Planned |
| 2 | EnemyBase.gd Base Class | P3 | Planned |
| 3 | Resource Caching | P4 | Planned |
| 4 | Debug Flag & Print Cleanup | P5 | Planned |
| 5 | player ↔ game_manager State Unification | P2 | Planned |
| 6 | Split game_manager.gd | P6 | Future |
| 7 | Audio Implementation | P7 | Future |
| 8 | game_balance.json Creation | P8 | Future |

---

## 5. Implementation Details

### 5.1 Save/Load System

**File**: `scripts/game_state.gd`

**Save Format**: JSON via `ConfigFile` at `user://save_game.cfg`

**Saved Fields**:
- `star_coin`, `minerals_low`, `minerals_mid`, `minerals_high`
- `unlocked_ships` (Array)
- `equipment_inventory` (Array of Dictionaries)
- `equipped_weapons` (Dictionary keyed by ship_id)
- `equipped_armor` (Dictionary keyed by ship_id)
- `upgraded_ships` (Dictionary keyed by ship_id)
- `ship_damaged`
- `total_kills`, `total_deaths`, `highest_level`
- `first_run`
- `selected_race_id`, `selected_ship_id`
- `player_name`

### 5.2 EnemyBase.gd

**File**: `scripts/enemy_base.gd`

**Shared Methods**:
- `_spawn_damage_number(amount, is_crit)` — floating damage labels
- `_spawn_death_effect()` — particle explosion
- `_start_hit_flash()` — white flash on damage
- `_get_player()` — safe player reference
- `_update_hp_bar()` — synchronized HP bar updates
- `setup_enemy(gm, hp, damage, speed)` — standardized init
- `take_damage(amount, is_crit)` — shared damage handling

**Extending Classes**:
- `EnemyMelee` — melee chase + contact damage
- `EnemySentry` — ranged, distance-keeping AI
- `EnemyRaven` — suicide bomber
- `BossVoid` — boss with rage mode

### 5.3 Resource Caching

**Pattern**:
```gdscript
static var _cache: Dictionary = {}

static func get_ship(ship_id: ShipID) -> ShipData:
    if _cache.has(ship_id):
        return _cache[ship_id]
    var ship = _create_ship_instance(ship_id)
    _cache[ship_id] = ship
    return ship
```

---

## 6. Code Conventions

- **Naming**: snake_case for variables/functions, PascalCase for classes/signals/enums
- **Types**: Always use explicit type hints
- **Null Checks**: Use `is_instance_valid()` for freed nodes
- **Signals**: Use typed signals (`signal x(val: int)`)
- **Constants**: SCREAMING_SNAKE_CASE or `@export` for editor values
- **Debug**: `const DEBUG := false` — never leave as `true` in commits

---

## 7. Game Balance Reference

### Enemy Scaling
- Every 20 kills: `enemy_hp *= 1.1`, `spawn_interval -= 0.1` (min 0.8s)
- Boss spawns at 50 kills
- Boss HP: 500, Rage at 60% HP

### Reward Scaling
- Combo multiplier: 3x at 30+, 2.5x at 20+, 2x at 10+, 1.5x at 5+
- Death: 50% reward penalty
- Self-destruct: 0% reward

### Ship Tonnage Tiers
- SMALL (Frigate/Corvette): Only SMALL equipment
- MEDIUM (Cruiser): SMALL + MEDIUM
- LARGE (Battlecruiser/Battleship): SMALL + MEDIUM + LARGE
- FLAGSHIP (Dreadnought/Titan): Any tier

---

## 8. File Manifest

```
scripts/
├── game_state.gd          (Autoload — global state)
├── sound_manager.gd        (Autoload — audio)
├── game_balance_loader.gd  (Autoload — config loader)
├── game_scene.gd          (Game scene controller)
├── game_manager.gd        (Combat core — NEEDS REFACTOR)
├── player.gd              (Player controller — NEEDS REFACTOR)
├── hud.gd                 (In-game HUD)
├── upgrade_menu.gd        (Level-up UI)
├── pause_menu.gd          (Pause menu)
├── base_scene.gd          (Base station UI)
├── base_pause_menu.gd
├── shop_ui.gd             (Equipment shop)
├── warehouse_ui.gd        (Equipment management)
├── shipyard_ui.gd         (Ship unlock/upgrade)
├── ship_storage.gd
├── repair_station.gd
├── crafting_table.gd       (Crafting system)
├── character_create.gd
├── race_select.gd
├── main_menu.gd
├── settlement_scene.gd
├── enemy_base.gd          (NEW — enemy base class)
├── enemy_melee.gd
├── enemy_sentry.gd
├── enemy_raven.gd
├── boss_void.gd
├── boss_bullet.gd
├── sentry_bullet.gd
├── missile.gd
├── cannon_bullet.gd
├── railgun_bullet.gd
├── laser_beam.gd
├── exp_orb.gd
├── damage_number.gd
├── parallax_starfield.gd
├── boss_warning.gd
└── newbie_guide.gd

resources/
├── ship_data.gd
├── weapon_data.gd
├── equipment_data.gd
├── shop_data.gd
├── race_data.gd
└── game_balance.json      (TO CREATE)

scenes/   (30+ .tscn files)
└── [See directory]
```
