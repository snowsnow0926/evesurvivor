# BOSS系统说明文档

> 版本：v2.0 | 日期：2026-05-13 | 状态：已完成

## 一、系统概述

BOSS系统为类幸存者EVE同人游戏提供独立的BOSS战体验，支持任意数量BOSS的注册管理、独立登场动画、狂暴阶段、多阶段攻击模式，以及统一的伤害数字和死亡特效。

---

## 二、架构总览

### 2.1 组件关系

```
┌─────────────────────────────────────────────────────────┐
│                    BossRegistry                          │
│  (Autoload) —— 所有BOSS的元数据中心                      │
│  _boss_entries       BOSS ID → BossEntry 字典            │
│  _chapter_boss_map   章节 → 默认BOSS ID                  │
│  _chapter_stage_boss_map  章节_关卡 → BOSS ID（精确匹配）│
└─────────────────────────────────────────────────────────┘
                           ▲
                           │ get_chapter_stage_boss()
┌─────────────────────────────────────────────────────────┐
│                    SpawnManager                         │
│  通过 BossRegistry 获取当前章节+关卡的BOSS                │
│  调用 BossEncounterUI 播放登场动画                       │
│  动画结束后才 instantiate BOSS                          │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                  BossEncounterUI                        │
│  全屏UI叠加层，播放BOSS登场动画                          │
│  立绘/Icon + 名称 + 章节信息                            │
│  emit encounter_finished → SpawnManager                  │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                     BossBase                            │
│  (extends EnemyBase)                                   │
│  setup_from_entry() — 一行代码初始化所有元数据          │
│  通用：狂暴模式、接触伤害、死亡奖励、伤害数字、特效      │
│  抽象：子类覆盖攻击模式方法                             │
└─────────────────────────────────────────────────────────┘
                           ▲
                           │ extends
┌──────────┬──────────────────┬──────────────┬───────────┐
│ BossVoid │ BossChongsan     │ BossQianpojun│  ...      │
│ 虚空领主  │ 冲三杀手         │ 钱破军       │           │
└──────────┴──────────────────┴──────────────┴───────────┘
```

### 2.2 BOSS登场流程

```
触发条件达成
    │
    ▼
SpawnManager 检测到BOSS触发
    │
    ▼
BossRegistry.get_chapter_stage_boss(chapter_id, stage_id) → BossEntry
    │
    ▼
BossEncounterUI.show_encounter(entry)    [动画 ~2.9s]
    ├── 暗色遮罩淡入 (0.3s)
    ├── 警告闪烁循环 + 警告音效 "boss_appear"
    ├── 音乐切换 "battle_boss"
    ├── BOSS立绘/Icon从屏幕下方升起 (1.2s)
    ├── BOSS名称+副标题+章节淡入 (0.4s)
    └── 全部淡出 + emit encounter_finished
    │
    ▼
SpawnManager 收到信号
    │
    ▼
正式 instantiate BOSS 场景 + setup_from_entry() + setup_boss()
    │
    ▼
BOSS进入战场
```

---

## 三、核心数据结构

### 3.1 BossEntry

定义在 `resources/boss_entry.gd`（`class_name BossEntry, extends RefCounted`）：

```gdscript
# === 身份 ===
var boss_id: String          # 唯一标识，如 "boss_qianpojun"
var name_zh: String          # 中文名，如 "钱破军"
var name_en: String          # 英文名，如 "Boss Qianpojun"
var icon_id: String           # icon_definitions.json 中的ID
var portrait_path: String     # 立绘图片路径（可为空）
var chapter: int             # 所属章节（1-6）
var tonnage: String           # 吨位分类 "boss"

# === 视觉 ===
var base_tint: Color               # 基础色调
var rage_tint: Color               # 狂暴时色调
var particle_color: Color          # 死亡粒子颜色
var visual_scale: float            # 精灵缩放倍率
var hp_bar_width: float           # HP条宽度
var hit_flash_intensity: float     # 受击闪烁强度（对亮度的影响倍率）
var damage_number_font_size_normal: int
var damage_number_font_size_crit: int
var damage_number_offset_x_range: float
var damage_number_offset_y: float
var damage_number_anim_offset: float
var damage_number_anim_duration: float
var damage_number_color_normal: Color
var damage_number_color_crit: Color

# === 战斗 ===
var rage_hp_threshold: float    # 狂暴触发血量阈值（0.0-1.0）
var collision_radius: float     # 碰撞半径
var collision_damage: float    # 接触伤害
var contact_cooldown: float     # 接触伤害冷却
var move_speed: float          # 移动速度
var bullet_scene_path: String   # 子弹场景路径
var bullet_speed: float        # 子弹速度
var bullet_damage: float       # 子弹基础伤害

# === 死亡特效 ===
var death_particle_count: int
var death_particle_lifetime: float
var death_particle_velocity_min: float
var death_particle_velocity_max: float
var death_particle_scale_min: float
var death_particle_scale_max: float
var death_burst_count: int
var death_exp_orb_count: int

# === 方法 ===
func get_bullet_scene() -> PackedScene
func has_portrait() -> bool    # portrait_path 不为空且文件存在时返回 true
```

### 3.2 章节-BOSS映射规则

| 映射方式 | 优先级 | 用途 |
|---------|--------|------|
| `_chapter_stage_boss_map` | 高 | 精确匹配"章节_关卡"（如 `"1_6" → "boss_qianpojun"`） |
| `_chapter_boss_map` | 低 | 章节默认BOSS（精确匹配未覆盖时回退） |

---

## 四、文件结构

| 文件路径 | 职责 |
|---------|------|
| `resources/boss_entry.gd` | `BossEntry` 数据类定义 |
| `scripts/boss_registry.gd` | BOSS注册中心，Autoload |
| `scripts/boss_base.gd` | BOSS基类，extends `EnemyBase` |
| `scripts/boss_encounter_ui.gd` | 登场UI逻辑控制 |
| `scenes/BossEncounterUI.tscn` | 登场UI场景 |
| `scripts/boss_void.gd` | 虚空领主逻辑 |
| `scenes/BossVoid.tscn` | 虚空领主场景 |
| `scripts/boss_chongsan.gd` | 冲三杀手逻辑 |
| `scenes/BossChongsan.tscn` | 冲三杀手场景 |
| `scripts/boss_qianpojun.gd` | 钱破军逻辑 |
| `scenes/BossQianpojun.tscn` | 钱破军场景 |
| `scripts/spawn_manager.gd` | BOSS生成调度，接入 `BossRegistry` |
| `resources/icon_definitions.json` | BOSS图标定义 |
| `scenes/GameScene.tscn` | 挂载 `BossEncounterUI` |

---

## 五、已注册BOSS

### 5.1 虚空领主 (BossVoid)

**所属章节**: 第1章·黑渊之地 | **关卡映射**: 第1章默认BOSS

#### 基础属性

| 属性 | 值 |
|------|-----|
| 基础色调 | `#800080` (紫色) |
| 狂暴色调 | `#FF3333` (红色) |
| 狂暴阈值 | 60% HP |
| 碰撞半径 | 40 |
| 接触伤害 | 15 / 0.5s |
| 移动速度 | 80 px/s |
| 狂暴速度加成 | ×1.2 |
| HP条宽度 | 102 |
| 受击闪烁 | 3.0x 亮度 |
| 视觉缩放 | 1.2 |

#### 子弹参数

| 参数 | 值 |
|------|-----|
| 子弹速度 | 400 px/s |
| 子弹伤害 | 10 |

#### 攻击技能

| 阶段 | 技能 | 描述 |
|------|------|------|
| 通用 | 追踪移动 | 持续向玩家移动 |
| 阶段一 | 扇形弹幕 | 每 1.5s，3 发呈扇形散开 |
| 狂暴 | 扇形弹幕 | 每 1.0s，6 发，角度更宽 |

#### 死亡特效

| 属性 | 值 |
|------|-----|
| 粒子颜色 | 紫色 |
| 粒子数量 | 40 |
| 爆发次数 | 5 |
| 经验球数量 | 10 |

---

### 5.2 冲三杀手 (BossChongsan)

**所属章节**: 第1章·黑渊之地 | **关卡映射**: 第1章·第5关

#### 基础属性

| 属性 | 值 | 说明 |
|------|-----|------|
| 基础色调 | `#00CCCC` (青色) | |
| 狂暴色调 | `#FF8800` (橙色) | |
| 狂暴阈值 | 50% HP | |
| 碰撞半径 | 40 | |
| 接触伤害 | 15 → 20 | 狂暴后上升 |
| 移动速度 | 100 px/s | 狂暴时 ×1.3 |
| HP条宽度 | 102 | |
| 受击闪烁 | 3.0x 亮度 | |
| 视觉缩放 | 1.2 | |
| 狂暴触发间隔 | 1.0s (原本 1.5s) | |

#### 子弹参数

| 参数 | 值 |
|------|-----|
| 子弹速度 | 380 px/s |
| 子弹伤害 | 8 |

#### 攻击技能

| 阶段 | 技能 | 描述 |
|------|------|------|
| 通用 | 追踪移动 | 持续向玩家移动，速度随狂暴提升 |
| 阶段一 (HP>50%) | 3连扇形弹幕 | 每 1.5s，3 发呈扇形散开 |
| 阶段一 (HP>50%) | 1 发追踪弹 | 扇形后 0.2s，朝玩家发射 |
| 阶段二 (狂暴) | 5连扇形弹幕 | 每 1.0s，5 发，角度更宽 |
| 阶段二 (狂暴) | 2 发追踪弹 | 扇形后 0.12s 发射 |
| 阶段二 (狂暴) | 突进冲刺 | 距玩家 <350px 时触发，0.4s 预警后高速冲刺，伤害 ×1.5 |

#### 突进冲刺详细

| 参数 | 值 |
|------|-----|
| 触发距离 | < 350px |
| 预警时间 | 0.4s |
| 冲刺速度 | 800 px/s（狂暴时 1200 px/s）|
| 冲刺持续 | 0.5s |
| 伤害 | 接触即造成 伤害×1.5 |
| 冷却时间 | 3.0s（狂暴时 1.0s）|

#### 死亡特效

| 属性 | 值 |
|------|-----|
| 粒子颜色 | 青色 |
| 粒子数量 | 40 |
| 爆发次数 | 5 |
| 经验球数量 | 12 |

---

### 5.3 钱破军 (BossQianpojun)

**所属章节**: 第1章·黑渊之地 | **关卡映射**: 第1章·第6关

#### 基础属性

| 属性 | 值 | 说明 |
|------|-----|------|
| 基础色调 | `#CCAA00` (金色) | |
| 狂暴色调 | `#FF2222` (红色) | |
| 狂暴阈值 | 40% HP | 相对较高难度 |
| 碰撞半径 | 40 | |
| 接触伤害 | 25 | 所有BOSS中最高 |
| 移动速度 | 90 px/s | 狂暴时 ×1.2 |
| HP条宽度 | 102 | |
| 受击闪烁 | 1.5x 亮度 | 已调低防止过曝 |
| 视觉缩放 | 1.3 | |
| 狂暴触发间隔 | 1.8s (原本 2.5s) | |

#### 子弹参数

| 参数 | 环形弹幕 | 直线弹 |
|------|---------|--------|
| 子弹速度 | 420 px/s | 630 px/s (×1.5) |
| 子弹伤害 | 15 | 30 (×2) |

#### 攻击技能

| 阶段 | 技能 | 描述 |
|------|------|------|
| 通用 | 追踪移动 | 持续向玩家移动 |
| 阶段一 (HP>40%) | 8连环形弹幕 | 每 2.5s，向四周均匀发射 8 发子弹 |
| 阶段一 (HP>40%) | 3 发正面直线弹 | 环形弹幕后 0.2s 发射，朝玩家方向，伤害翻倍 |
| 阶段二 (狂暴) | 16连环形弹幕 | 每 1.8s，16 发环形弹幕，覆盖范围更大 |
| 阶段二 (狂暴) | 5 发正面直线弹 | 直线弹伤害翻倍 |

#### 死亡特效

| 属性 | 值 |
|------|-----|
| 粒子颜色 | 金色 |
| 粒子数量 | 50 |
| 爆发次数 | 6 |
| 粒子寿命 | 1.2s |
| 经验球数量 | 12 |

---

### 5.4 BOSS属性对比总览

| 属性 | 虚空领主 | 冲三杀手 | 钱破军 |
|------|---------|---------|--------|
| 狂暴阈值 | 60% HP | 50% HP | 40% HP |
| 狂暴变色 | 紫→红 | 青→橙 | 金→红 |
| 基础色调 | #800080 | #00CCCC | #CCAA00 |
| 移动速度 | 80 | 100 | 90 |
| 狂暴速度 | ×1.2 | ×1.3 | ×1.2 |
| 接触伤害 | 15 | 15→20 | 25 |
| 子弹伤害 | 10 | 8 | 15 |
| 子弹速度 | 400 | 380 | 420 |
| 攻击特点 | 扇形扩散 | 突进冲刺 | 环形弹幕+直线弹 |
| 难度定位 | 入门 | 中等 | 较难 |

---

## 六、登场UI设计

### 6.1 布局

```
┌─────────────────────────────────────────────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│                                                             │
│                    ┌─────────────────┐                       │
│                    │   BOSS 立绘    │  ← 从下方升起，居中   │
│                    │  或放大 Icon    │    display           │
│                    │  (scale=1.5)   │                       │
│                    └─────────────────┘                       │
│                                                             │
│                  ┌───────────────────┐                      │
│                  │   警告：钱破军   │  ← 红色闪烁文字       │
│                  │   BOSS QIANPOJUN │                      │
│                  │  第一章·黑渊之地 │  ← 章节副标题         │
│                  └───────────────────┘                      │
│                                                             │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
└─────────────────────────────────────────────────────────┘
              暗色遮罩（半透明黑色，alpha ≈ 0.78）
```

### 6.2 节点结构

| 节点 | 类型 | 说明 |
|------|------|------|
| `BossEncounterUI` | Control | 根节点，填充全屏 |
| `Overlay` | ColorRect | 暗色遮罩层 |
| `WarningLabel` | Label | 警告文字，红色闪烁 |
| `PortraitContainer` | Control | 立绘容器，填充全屏 |
| `PortraitSprite` | Sprite2D | BOSS立绘（position居中，scale=1.5）|
| `IconSprite` | Sprite2D | 无立绘时回退，显示icon（modulate=1.5x亮度）|
| `NameContainer` | VBoxContainer | 名称文字容器 |
| `NameLabel` | Label | BOSS中文名，红色，48px |
| `SubtitleLabel` | Label | BOSS英文名，粉红，24px |
| `ChapterLabel` | Label | 章节信息，灰色，18px |

### 6.3 动画时序

| 时间 | 事件 |
|------|------|
| 0.0s | 暗色遮罩淡入 + 警告闪烁 + 警告音效 + 音乐切换 |
| 0.3s | 遮罩 alpha 达到 0.78 |
| 0.3s | BOSS立绘/Icon 从 y+700 开始升起 |
| 1.5s | 立绘到达屏幕中心位置 |
| 1.5s | BOSS名称+副标题+章节淡入 (0.4s) |
| 1.9s | 名称文字完全显示 |
| 2.9s | 全部淡出，emit encounter_finished |

### 6.4 立绘与Icon显示规则

```
has_portrait() == true
    → PortraitSprite 显示立绘 (scale=1.5，居中)
    → IconSprite 隐藏

has_portrait() == false
    → PortraitSprite 隐藏
    → IconSprite 显示 (modulate=1.5x 亮度，居中)
```

`has_portrait()` 判断条件：`portrait_path` 不为空 **且** 文件存在。

---

## 七、Autoload配置

```
BossRegistry (自动加载)
  - 执行顺序：默认
  - 场景：_为空_（纯脚本，无场景文件）
```

---

## 八、扩展指南：添加新BOSS

### 步骤1：注册到 BossRegistry

在 `scripts/boss_registry.gd` 的 `_register_all_bosses()` 中添加：

```gdscript
var new_entry := BossEntry.new(
    "boss_new",          # boss_id，全局唯一
    "新BOSS名",          # name_zh
    "Boss New",          # name_en
    "boss_new",          # icon_id，需在 icon_definitions.json 中定义
    "res://assets/races/new_portrait.png",  # portrait_path，可为空 ""
    1,                   # chapter
    "boss",              # tonnage
    Color(0.5, 0.0, 0.5),   # base_tint
    Color(1.0, 0.2, 0.2),   # rage_tint
    # ... 其他参数见 BossEntry 定义
)
_register_boss(new_entry)
# 精确匹配（可选）
_chapter_stage_boss_map["1_7"] = "boss_new"
# 或回退映射
_chapter_boss_map[1] = "boss_new"
```

### 步骤2：添加图标定义

在 `resources/icon_definitions.json` 的 `enemies` 数组中添加：

```json
{
    "id": "boss_new",
    "name_en": "Boss New",
    "name_zh": "新BOSS名",
    "texture_path": "res://assets/newship/enemy/BossNew.png",
    "tonnage": "boss",
    "path": []
}
```

### 步骤3：创建BOSS脚本

新建 `scripts/boss_new.gd`，继承 `BossBase`：

```gdscript
extends BossBase

func _ready() -> void:
    _base_tint = Color(0.5, 0.0, 0.5)
    _visual_scale = 1.2
    _icon_id = "boss_new"
    tonnage = "boss"
    _hp_bar_max_width = 102.0
    _hit_flash_intensity = 3.0
    super._ready()

func _process_combat(delta: float) -> void:
    _process_movement(delta)
    _process_contact_damage(_get_player())
    _process_rage_check()
    _process_attack_pattern(delta)

func _process_attack_pattern(delta: float) -> void:
    # 实现攻击逻辑

func _enter_rage_mode() -> void:
    super._enter_rage_mode()
    _base_tint = Color(1.0, 0.2, 0.2)
    _update_shader_params()

func _die() -> void:
    # 死亡逻辑
    super._die()
```

### 步骤4：创建BOSS场景

新建 `scenes/BossNew.tscn`：

```gdscript
[gd_scene format=3 uid="uid://新uid"]

[ext_resource type="Script" path="res://scripts/boss_new.gd" id="1"]

[sub_resource type="CircleShape2D" id="CircleShape2D"]
radius = 40.0

[node name="BossNew" type="CharacterBody2D"]
collision_layer = 2
collision_mask = 5
script = ExtResource("1")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
rotation = 1.5708
shape = SubResource("CircleShape2D")

[node name="ShipSprite" type="Sprite2D" parent="."]

[node name="HPBarBg" type="ColorRect" parent="."]
# ... HP条节点
```

### 步骤5：在注册中心添加场景路径

在 `boss_registry.gd` 的 `_get_scene_path_for_boss()` 中添加匹配分支：

```gdscript
func _get_scene_path_for_boss(boss_id: String) -> String:
    match boss_id:
        "boss_void":      return "res://scenes/BossVoid.tscn"
        "boss_chongsan":   return "res://scenes/BossChongsan.tscn"
        "boss_qianpojun":  return "res://scenes/BossQianpojun.tscn"
        "boss_new":        return "res://scenes/BossNew.tscn"  # 新增
    return "res://scenes/BossVoid.tscn"
```

---

## 九、技术约束

- 所有BOSS场景文件必须放在 `scenes/` 目录
- 所有BOSS脚本必须放在 `scripts/` 目录
- `boss_id` 全局唯一，不允许重复
- BOSS登场UI使用 `Control` 节点，挂在游戏场景中
- BOSS立绘优先使用 `portrait_path`，无立绘时回退到 `icon_id` 放大显示
- 立绘 Sprite2D 使用 `position = (960, 540)` 居中，`scale = 1.5` 填满屏幕
- 受击闪烁强度建议设置在 `1.5 ~ 3.0` 之间，过高会导致画面过曝
- 狂暴变色通过 `_base_tint` 和 `_update_shader_params()` 实现
