# BOSS系统架构设计

> 版本：v1.0 | 日期：2026-05-12 | 状态：实现中

## 一、设计目标

为类幸存者EVE同人游戏建立一套可扩展的BOSS系统架构，支持：

- 任意数量的BOSS注册与管理
- 每个BOSS拥有独立的登场动画与立绘展示
- 统一的BOSS生成与生命周期管理
- 清晰的章节-BOSS映射关系
- 最小化新增BOSS时的代码改动量

---

## 二、系统架构

### 2.1 组件关系图

```
┌─────────────────────────────────────────────────────────────────┐
│                        BossRegistry                              │
│  (Autoload) —— 所有BOSS的元数据中心，注册表入口                   │
│  - _chapter_boss_map  章节 → BOSS ID 映射                       │
│  - _boss_entries      BOSS ID → BossEntry 字典                   │
│  - get_boss_entry(id) / get_chapter_boss(chapter) / ...         │
└─────────────────────────────────────────────────────────────────┘
                                    ▲
                                    │ get_boss_entry()
┌─────────────────────────────────────────────────────────────────┐
│                      SpawnManager                                │
│  - 不再hardcode BOSS场景路径                                     │
│  - 通过 BossRegistry 获取当前章节对应的BOSS                       │
│  - 调用 BossEncounterUI 播放登场动画                             │
│  - 动画结束后才真正 instantiate BOSS                             │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                     BossEncounterUI                              │
│  (全屏UI叠加层)                                                  │
│  - 全屏暗色遮罩淡入                                              │
│  - BOSS立绘 / icon 从下方升起                                   │
│  - 显示 BOSS名称（中/英）+ 副标题                               │
│  - 播放警告音效                                                 │
│  - 动画结束后 emit encounter_finished → SpawnManager             │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                       BossBase                                   │
│  (所有BOSS的基类，extends EnemyBase)                            │
│  - setup_from_entry(entry)  ← 一行代码初始化所有元数据          │
│  - 通用：狂暴模式、接触伤害、死亡奖励、伤害数字                  │
│  - 抽象：子类覆盖 _get_attack_pattern() 等方法                  │
└─────────────────────────────────────────────────────────────────┘
                                    ▲
                                    │ extends
    ┌─────────────────┬──────────────────────┬─────────────┐
    │  BossVoid       │  BossChongsan        │  ...       │
    │  (虚空领主)     │  (冲三杀手)          │            │
    │  - 扇形弹幕     │  - 突进+三连弹       │            │
    │  - 60%狂暴      │  - 低HP连续突进      │            │
    └─────────────────┴──────────────────────┴─────────────┘
```

### 2.2 BOSS登场流程

```
触发条件达成
    │
    ▼
SpawnManager 检测到BOSS触发
    │
    ▼
BossRegistry.get_chapter_boss(chapter_id) → BossEntry
    │
    ▼
BossEncounterUI.show_encounter(entry)    [动画 ~2.5s]
    ├── 暗色遮罩淡入 (0.3s)
    ├── 警告音效 "boss_appear" 播放
    ├── 音乐切换 "battle_boss"
    ├── 立绘从屏幕下方升起
    ├── BOSS名称淡入显示
    └── 动画结束 → emit encounter_finished
    │
    ▼
SpawnManager 收到信号
    │
    ▼
正式 instantiate BOSS 场景
    │
    ▼
调用 boss.setup_from_entry(entry)  +  boss.setup_boss(...)
    │
    ▼
BOSS进入战场（屏幕震动+白光特效保持不变）
```

---

## 三、核心数据结构

### 3.1 BossEntry

每个BOSS的元数据包，定义在 `resources/boss_entry.gd`（`class_name BossEntry, extends RefCounted`）：

```gdscript
class_name BossEntry
extends RefCounted

var boss_id: String          # 唯一标识，如 "boss_void"
var name_zh: String          # 中文名，如 "虚空领主"
var name_en: String          # 英文名，如 "Boss Void"
var icon_id: String          # icon_definitions.json 中的ID
var portrait_path: String     # 立绘图片路径（可为空）
var chapter: int             # 所属章节（1-6）
var tonnage: String          # 吨位分类 "boss"

# === 视觉 ===
var base_tint: Color         # 基础色调
var rage_tint: Color         # 狂暴时色调
var particle_color: Color    # 死亡粒子颜色
var visual_scale: float      # 精灵缩放倍率
var hp_bar_width: float      # HP条宽度（默认102）
var hit_flash_intensity: float  # 受击闪烁强度
var damage_number_font_size_normal: int
var damage_number_font_size_crit: int

# === 战斗 ===
var rage_hp_threshold: float      # 狂暴触发血量阈值（0.0-1.0，默认0.6）
var collision_radius: float       # 碰撞半径（默认40）
var contact_damage: float         # 接触伤害
var contact_cooldown: float       # 接触伤害冷却
var bullet_scene_path: String     # 子弹场景路径
var bullet_speed: float           # 子弹速度
var bullet_damage: float          # 子弹基础伤害

# === 死亡特效 ===
var death_particle_count: int     # 死亡粒子数量
var death_burst_count: int        # 死亡爆发次数
var death_particle_lifetime: float
var death_exp_orb_count: int      # 死亡掉落经验球数量
```

---

## 四、文件结构

| 文件路径 | 类型 | 职责 |
|----------|------|------|
| `resources/boss_entry.gd` | 新建 | `BossEntry` 数据类定义 |
| `scripts/boss_registry.gd` | 新建 | BOSS注册中心，Autoload |
| `scripts/boss_base.gd` | 新建 | BOSS基类，extends `EnemyBase` |
| `scripts/boss_encounter_ui.gd` | 新建 | 登场UI逻辑控制 |
| `scenes/BossEncounterUI.tscn` | 新建 | 登场UI场景 |
| `scripts/boss_void.gd` | 修改 | 改为继承 `BossBase` |
| `scenes/BossVoid.tscn` | 修改 | 关联新脚本 |
| `scripts/spawn_manager.gd` | 修改 | 接入 `BossRegistry` |
| `resources/icon_definitions.json` | 修改 | 添加BOSS条目 |
| `scenes/GameScene.tscn` | 修改 | 挂载 `BossEncounterUI` |
| `scenes/BossChongsan.tscn` | 后续 | 冲三杀手场景 |
| `scripts/boss_chongsan.gd` | 后续 | 冲三杀手逻辑 |
| `scenes/BossQianpojun.tscn` | 后续 | 钱破军场景 |
| `scripts/boss_qianpojun.gd` | 后续 | 钱破军逻辑 |

---

## 五、已注册BOSS

### 5.1 虚空领主 (BossVoid)

| 属性 | 值 |
|------|-----|
| BOSS ID | `boss_void` |
| 中文名 | 虚空领主 |
| 英文名 | Boss Void |
| 所属章节 | 第1章·黑渊之地 |
| 基础色调 | `#800080` (紫色) |
| 狂暴色调 | `#FF3333` (红色) |
| 狂暴阈值 | 60% HP |
| 接触伤害 | 15 |
| 子弹伤害 | 10 |
| 子弹速度 | 400 |
| 攻击模式 | 扇形弹幕（3发普通 / 5发狂暴）|
| 死亡粒子 | 紫色，40粒子，5次爆发 |

### 5.2 冲三杀手 (BossChongsan) — 待实现

| 属性 | 值 |
|------|-----|
| BOSS ID | `boss_chongsan` |
| 中文名 | 冲三杀手 |
| 英文名 | Boss Chongsan |
| 所属章节 | 第2章·婓德之境 |
| 基础色调 | `#00CCCC` (青色) |
| 狂暴色调 | `#FF8800` (橙色) |
| 狂暴阈值 | 50% HP |
| 接触伤害 | 20 |
| 子弹伤害 | 8 |
| 攻击模式 | 三连弹扇形 + 低HP突进冲刺 |
| 死亡粒子 | 青色 |

### 5.3 钱破军 (BossQianpojun) — 待实现

| 属性 | 值 |
|------|-----|
| BOSS ID | `boss_qianpojun` |
| 中文名 | 钱破军 |
| 英文名 | Boss Qianpojun |
| 所属章节 | 第3章·德克廉深渊 |
| 基础色调 | `#CCAA00` (金色) |
| 狂暴色调 | `#FF2222` (红色) |
| 狂暴阈值 | 40% HP |
| 接触伤害 | 25 |
| 子弹伤害 | 15 |
| 攻击模式 | 环形弹幕 + 正面高伤害直线弹 |
| 死亡粒子 | 金色 |

---

## 六、登场UI设计

### 6.1 布局

```
┌─────────────────────────────────────────────────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│                                                             │
│                     ┌──────────────────┐                   │
│                     │    BOSS 立绘      │                   │
│                     │  (或放大icon)      │  ← 从下方升起     │
│                     └──────────────────┘                   │
│                                                             │
│                   ┌──────────────────┐                     │
│                   │   警告：虚空领主  │  ← 红色闪烁文字    │
│                   │   BOSS VOID       │                     │
│                   │  第一章·黑渊之地  │  ← 章节副标题      │
│                   └──────────────────┘                     │
│                                                             │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
└─────────────────────────────────────────────────────────────┘
         暗色遮罩（半透明黑色，alpha ≈ 0.7）
```

### 6.2 动画时序

| 时间 | 事件 |
|------|------|
| 0.0s | 暗色遮罩淡入 |
| 0.3s | 警告音效触发，音乐切换 |
| 0.5s | BOSS立绘从 y+300 位置开始升起 |
| 1.2s | 立绘到达中心位置，停止 |
| 1.5s | BOSS名称文字淡入显示 |
| 2.5s | 遮罩淡出，动画完成，emit信号 |

---

## 七、Autoload配置

```
BossRegistry (自动加载)
  - 执行顺序：默认（不需要特别设置优先级）
  - 场景：_为空_（纯脚本，无场景文件）
```

---

## 八、扩展指南：添加新BOSS

### 步骤1：注册到 BossRegistry

在 `boss_registry.gd` 的 `_register_all_bosses()` 中添加：

```gdscript
_register_boss(BossEntry.new(
    boss_id = "boss_new",
    name_zh = "新BOSS名",
    name_en = "Boss New",
    icon_id = "boss_new",
    ...
))
_chapter_boss_map[章节号] = "boss_new"
```

### 步骤2：添加图标定义

在 `resources/icon_definitions.json` 添加：

```json
{
    "id": "boss_new",
    "name_en": "Boss New",
    "name_zh": "新BOSS名",
    "texture_path": "res://assets/.../BossNew.png",
    "tonnage": "boss",
    "path": []
}
```

### 步骤3：创建BOSS脚本

新建 `scripts/boss_new.gd`，继承 `BossBase`，覆盖攻击模式方法。

### 步骤4：创建BOSS场景

新建 `scenes/BossNew.tscn`，挂载新脚本，配置碰撞体和视觉节点。

### 步骤5：（可选）添加立绘

准备PNG立绘图片，设置 `BossEntry.portrait_path`。

---

## 九、技术约束

- 所有BOSS场景文件必须放在 `scenes/` 目录
- 所有BOSS脚本必须放在 `scripts/` 目录
- `boss_id` 全局唯一，不允许重复
- BOSS登场UI使用 `Control` 节点，挂在 `UIRoot` 下
- BOSS立绘优先使用 `portrait_path`，无立绘时回退到 `icon_id` 放大显示
