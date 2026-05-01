# EVE SURVIVOR — UI/场景完整文档

> 记录日期: 2026-05-01
> 项目: 类幸存者eve同人
> Godot版本: 4.6.2

---

## 一、场景清单（全30个.tscn）

| 文件 | 根节点类型 | 说明 |
|------|-----------|------|
| `scenes/Main.tscn` | Node2D | 项目入口（占位符，UIRoot为空Control） |
| `scenes/GameScene.tscn` | Node2D | 战斗主场景，含GameManager和UIRoot |
| `scenes/HUD.tscn` | Control | 战斗HUD叠加层 |
| `scenes/UpgradeMenu.tscn` | Control | 升级选择界面（动态创建按钮） |
| `scenes/PauseMenu.tscn` | Control | 战斗暂停菜单 |
| `scenes/BossWarning.tscn` | Control | Boss来袭警告横幅 |
| `scenes/BaseScene.tscn` | Control | 基地管理主界面（所有子面板嵌入） |
| `scenes/SettlementScene.tscn` | Control | 战斗结算界面 |
| `scenes/MainMenu.tscn` | Control | 主菜单 |
| `scenes/CharacterCreate.tscn` | Control | 角色/种族创建 |
| `scenes/RaceSelect.tscn` | Control | 种族选择界面 |
| `scenes/ShipSelectUI.tscn` | Control | 出战舰船选择 |
| `scenes/ShopUI.tscn` | Control | 独立商店界面（BaseScene内嵌入ShopPanel复用） |
| `scenes/WarehouseUI.tscn` | Control | 独立仓库界面（BaseScene内嵌入WarehousePanel复用） |
| `scenes/ShipyardUI.tscn` | Control | 独立造船厂界面（BaseScene内嵌入ShipyardPanel复用） |
| `scenes/Player.tscn` | CharacterBody2D | 玩家舰船实体 |
| `scenes/BossVoid.tscn` | CharacterBody2D | Boss敌人实体 |
| `scenes/EnemyMelee.tscn` | CharacterBody2D | 近战敌人 |
| `scenes/EnemySentry.tscn` | CharacterBody2D | 哨兵敌人（会射击） |
| `scenes/EnemyRaven.tscn` | CharacterBody2D | 快速敌人 |
| `scenes/CannonBullet.tscn` | Area2D | 加农炮弹丸 |
| `scenes/Missile.tscn` | Area2D | 导弹弹丸 |
| `scenes/LaserBeam.tscn` | Area2D | 激光束 |
| `scenes/RailgunBullet.tscn` | Area2D | 磁轨炮弹丸 |
| `scenes/SentryBullet.tscn` | Area2D | 哨兵子弹 |
| `scenes/BossBullet.tscn` | Area2D | Boss子弹 |
| `scenes/ExpOrb.tscn` | Area2D | 经验球拾取物 |
| `scenes/DamageNumber.tscn` | Node2D | 浮动伤害数字 |

---

## 二、游戏流程与场景切换关系

```
MainMenu.tscn
    │
    ├── [StartBtn] → CharacterCreate.tscn
    │
    │                    CharacterCreate.tscn
    │                         │
    │                         └── [ConfirmBtn] → BaseScene.tscn
    │                                              │
    BaseScene.tscn ─────────────────────────────────┤
    │   │                                           │
    │   ├── [ShopBtn]    → 显示 ShopPanel          │
    │   ├── [WarehouseBtn] → 显示 WarehousePanel    │
    │   ├── [ShipyardBtn] → 显示 ShipyardPanel     │
    │   ├── [RepairBtn]  → 显示 RepairPanel        │
    │   ├── [CraftingBtn] → 显示 CraftingPanel     │
    │   ├── [StorageBtn] → 显示 StoragePanel        │
    │   ├── [StartBattleBtn] → ShipSelectUI.tscn    │
    │   │                                     │
    │   │                          ShipSelectUI.tscn
    │   │                               │
    │   │                               └── [出发] → GameScene.tscn
    │   │                                                       │
    │   │                                        GameScene.tscn
    │   │                                        /    |    \
    │   │                                     HUD  UpgradeMenu  PauseMenu
    │   │                                       |       |          |
    │   │                                    战斗中   升级选择   暂停
    │   │                                       |       |          |
    │   │                                       └───────┼──────────┘
    │   │                                               │
    │   │                                    [继续游戏] / [撤退结算] / [自毁退出]
    │   │                                               │
    │   │                                    结算 SettlementScene.tscn
    │   │                                    /       |         \
    │   │                               [重新开始]  [返回基地]  [主菜单]
    │   │                                   │          │          │
    │   │                                   ↓          ↓          ↓
    │   └── ← ← ← ← ← ← ← ← ← ← ← ← ← GameScene   BaseScene  MainMenu
    │
    └── [RepairsBtn] → 调用 GameState.repair_ship()
```

---

## 三、各场景详细节点清单

---

### 3.1 HUD.tscn — 战斗HUD（脚本: `hud.gd`）

#### 节点访问方式
- `@onready` 声明型：`$TopRightAnchor/MainPanel`
- `get_node()` 动态型：`$TopCenterAnchor/TopWeaponPanel/TopWeaponHBox/WeaponSlot1`
- `get_node_or_null()` 安全型：`$BottomRightAnchor/UpgradeListPanel/UpgradeListVBox/TitleLabel`

#### 节点树结构

```
HUD (Control, root)
│
├── ShipInfoPanel (PanelContainer)   # 左下角 — 舰船属性面板
│   └── ShipInfoVBox (VBoxContainer)
│       ├── ShipTitle (Label)        # 舰船名称，如 "NOVA STRIKER"
│       ├── HPLabel (Label)          # "HP: 100 / 100"
│       ├── ShieldLabel (Label)       # "护盾: 50 / 50"
│       ├── AtkLabel (Label)          # "攻击: 15"
│       ├── FireRateLabel (Label)     # "射速: 0.80s"
│       ├── SpeedLabel (Label)        # "移速: 320"
│       ├── CritLabel (Label)          # "暴击: 5%"
│       ├── DodgeLabel (Label)         # "闪避: 10%"
│       ├── Divider (HSeparator)
│       ├── RaceInfoLabel (Label)      # "种族: 人类"（蓝色）
│       ├── RaceBonusLabel (Label)     # "天赋: ..."（较小字体）
│       └── ShipSlotsLabel (Label)     # "武:0/2 | 防:0/1"（灰色）
│
├── TopCenterAnchor (Control)         # 顶部居中锚点
│   └── TopWeaponPanel (PanelContainer)
│       └── TopWeaponHBox (HBoxContainer)
│           ├── WeaponSlot1 (PanelContainer)
│           │   └── WeaponSlot1VBox (VBoxContainer)
│           │       ├── TypeLabel (Label)    # "[武器]"
│           │       └── Name (Label)         # "导弹 Lv.0"（含品质颜色）
│           ├── WeaponSlot2 (PanelContainer)
│           │   └── WeaponSlot2VBox
│           │       ├── TypeLabel
│           │       └── Name
│           ├── WeaponSlot3 (PanelContainer)
│           │   └── WeaponSlot3VBox...
│           ├── WeaponSlot4 (PanelContainer)
│           │   └── WeaponSlot4VBox...
│           ├── WeaponSlot5 (PanelContainer)
│           │   └── WeaponSlot5VBox...
│           ├── WeaponSlot6 (PanelContainer)
│           │   └── WeaponSlot6VBox...
│           └── DefenseSlot (PanelContainer)
│               └── DefenseSlotVBox
│                   ├── TypeLabel (Label)    # "[防御]"
│                   └── Name (Label)         # "空槽位" 或 "小型立场优化器 Lv.1"
│
├── TopRightAnchor (Control)          # 顶部居中锚点（v1.2改为水平居中）
│   ├── MainPanel (PanelContainer)
│   │   └── VBox (VBoxContainer)
│   │       ├── HPRow (HBoxContainer)
│   │       │   ├── HPLabel (Label)        # "HP:"
│   │       │   └── HPBar (ProgressBar)    # 红色血条
│   │       ├── XPRow (HBoxContainer)
│   │       │   ├── XPLabel (Label)        # "XP:"
│   │       │   └── XPBar (ProgressBar)    # 绿色经验条
│   │       └── InfoLabel (Label)          # "Level: 1 | Kills: 0 | Coin: 0" + combo提示
│   └── TimerLabel (Label)                  # "05:00" 倒计时，右上角
│
└── BottomRightAnchor (Control)       # 底部居中锚点（v1.2改为水平居中）
    └── UpgradeListPanel (PanelContainer)
        └── UpgradeListVBox (VBoxContainer)
            ├── TitleLabel (Label)          # "已获升级"（青色大字）
            ├── Divider (HSeparator)
            └── [动态创建的Label]           # 每个已获升级的名称和等级
```

#### 按钮列表
HUD本身无按钮，纯展示。通过 `_process()` 自动从 GameManager 同步数据。

---

### 3.2 UpgradeMenu.tscn — 升级选择（脚本: `upgrade_menu.gd`）

#### 节点访问方式
- 静态节点：直接在 `.tscn` 中定义
- 动态按钮：在 `_populate()` 中程序化创建

#### 节点树结构

```
UpgradeMenu (Control, root)
├── ColorRect                    # 半透明黑色遮罩 rgba(0,0,0,0.8)
├── CenterContainer (CenterContainer)
│   └── UpgradePanel (PanelContainer, 450x350)
│       └── VBox (VBoxContainer, 400x300)
│           └── TitleLabel (Label)   # "SELECT UPGRADE"
│
└── [动态创建的Button数组]       # 3个选项按钮，400x80，存储在 buttons[] 数组
```

#### 按钮列表

| 按钮 | 触发函数 | 行为 |
|------|---------|------|
| 动态升级按钮 | `_on_btn_pressed(upgrade_id)` | 发射 `upgrade_selected` 信号，GameScene接收并调用 `apply_upgrade()` |
| 键盘 ui_up | `move_selection(-1)` | 向上移动选择框 |
| 键盘 ui_down | `move_selection(1)` | 向下移动选择框 |
| 键盘 ui_accept | `confirm_selection()` | 确认当前选中项 |
| 键盘 ui_cancel | `skip_upgrade()` | 跳过本次升级 |

#### 信号
```gdscript
signal upgrade_selected(upgrade_id: String)
# 接收者: GameScene._on_upgrade_selected()
```

---

### 3.3 PauseMenu.tscn — 战斗暂停（脚本: `pause_menu.gd`）

#### 节点访问方式
`@onready`

#### 节点树结构

```
PauseMenu (Control, root)
├── Overlay (ColorRect)         # rgba(0,0,0,0.6) 半透明遮罩
└── Panel (Panel, 400x320)
    └── VBox (VBoxContainer)
        ├── TitleLabel (Label)       # "暂停"
        ├── ContinueBtn (Button)     # "继续游戏"
        ├── RetreatBtn (Button)      # "撤退结算"
        └── SelfDestructBtn (Button) # "自毁退出"
```

#### 按钮列表

| 按钮 | 触发函数 | 行为 |
|------|---------|------|
| ContinueBtn | `_on_continue_pressed()` | 调用 `close_menu()`，解除暂停 |
| RetreatBtn | `_on_retreat_pressed()` | 发射 `retreat_requested` + 调用 `game_manager.on_retreat()` |
| SelfDestructBtn | `_on_self_destruct_pressed()` | 发射 `self_destruct_requested` + 调用 `game_manager.on_self_destruct()` |

#### 信号
```gdscript
signal pause_toggled
signal retreat_requested
signal self_destruct_requested
```

---

### 3.4 BossWarning.tscn — Boss警告（脚本: `boss_warning.gd`）

#### 节点访问方式
直接路径 `$Panel/Label`

#### 节点树结构

```
BossWarning (Control, root)
└── Panel (Panel, 全宽60px高，底部对齐)
    └── Label (Label)   # "警告：检测到高强度信号……" 红色大字
```

无按钮。通过 `_start_flash()` 执行闪烁动画（tween动画）。

---

### 3.5 BaseScene.tscn — 基地管理（脚本: `base_scene.gd` 等）

这是最复杂的场景，所有子面板作为子节点嵌入，通过脚本独立管理。

#### 节点树结构

```
BaseScene (Control, root)
│
├── BG (ColorRect)              # 深色背景
│
├── Header (PanelContainer)     # 顶部标题栏
│   └── HBox
│       ├── Title (Label)       # "星际基地"
│       └── CurrencyBar
│           ├── CoinLabel       # "星币: 0"
│           └── MineralsLabel    # "矿物: 0低 / 0中 / 0高"
│
├── NavPanel (PanelContainer)   # 左侧导航按钮栏
│   └── VBox
│       ├── RepairBtn           # "维修站"
│       ├── CraftingBtn         # "装备合成"
│       ├── ShopBtn             # "武器商店"
│       ├── WarehouseBtn        # "物品仓库"
│       ├── ShipyardBtn         # "造船厂"
│       ├── StorageBtn          # "星港"
│       ├── ResetGameBtn        # "重置游戏"
│       └── StartBattleBtn      # "出发战斗"（醒目大字）
│
├── NoWeaponWarning (Label)      # 隐藏，无武器时弹出警告
│
├── ConfirmResetDialog (Control) # 重置确认对话框（隐藏）
│   ├── Overlay (ColorRect)
│   └── Panel
│       └── VBox
│           ├── Title: "确认重置？"
│           ├── Message: "此操作不可恢复！"
│           └── BtnRow
│               ├── CancelBtn   # "取消"
│               └── ConfirmBtn  # "确认重置"
│
│  ═══════════════════════════════════════
│  以下为所有子面板，初始 `visible = false`
│  ═══════════════════════════════════════
│
├── RepairPanel (Control)       # [脚本: repair_station.gd]
│   └── Panel
│       └── VBox
│           ├── Title: "维修站"
│           ├── ShipList (VBoxContainer)  # 动态填充，每艘舰船一行
│           ├── DetailLabel              # 显示选中舰船的维修费用
│           ├── RepairBtn                # "执行维修"
│           └── BackBtn                  # "返回"
│
├── CraftingPanel (Control)     # [脚本: crafting_table.gd]
│   └── Panel
│       └── VBox
│           ├── Title: "装备合成"
│           ├── InventoryLabel: "我的装备："
│           ├── InventoryGrid (GridContainer, 4列)  # 动态填充仓库物品
│           ├── CraftingSlotsLabel: "合成槽（放入2件相同品质装备）："
│           ├── CraftingSlots (HBoxContainer)
│           │   ├── Slot0 (PanelContainer) → Label "[空]"
│           │   └── Slot1 (PanelContainer) → Label "[空]"
│           ├── ResultPreview (Label)   # 合成预览/消耗说明
│           ├── CraftBtn                # "合成"
│           ├── QuickCraftBtn            # "一键合成"（v1.2新增）
│           └── BackBtn                 # "返回"
│
├── StoragePanel (Control)      # [脚本: ship_storage.gd]
│   └── Panel
│       └── VBox
│           ├── Title: "星港"
│           ├── ShipList (VBoxContainer)  # 动态填充
│           ├── EquipDetail              # 选中舰船详情
│           └── BackBtn                  # "返回"
│
├── ShopPanel (Control)         # [脚本: shop_ui.gd，与ShopUI.tscn共用]
│   └── Panel
│       └── VBox
│           ├── Title: "武器商店"
│           ├── TabHBox
│           │   ├── TabWeapons (Button)  # "武器" 切换标签
│           │   └── TabArmor (Button)    # "防御" 切换标签
│           ├── FilterHBox
│           │   ├── FilterAll    # "全部"
│           │   ├── FilterSmall  # "小型"
│           │   ├── FilterMedium # "中型"
│           │   ├── FilterLarge  # "大型"
│           │   └── FilterFlag   # "旗舰级"
│           ├── HBox
│           │   ├── LeftPanel
│           │   │   ├── WeaponListLabel   # "装备列表（全部）"
│           │   │   └── WeaponList (ScrollContainer)
│           │   │       └── VBox          # 动态填充商品按钮
│           │   └── RightPanel
│           │       ├── DetailTitle       # "[小型] 小型导弹发射器"
│           │       ├── DetailDesc        # 商品描述
│           │       ├── DetailStats       # 属性详情
│           │       ├── DetailCost        # 价格和出售价
│           │       ├── BuyBtn             # "购买"
│           │       └── SellBtn            # "出售"
│           └── Footer
│               ├── CoinLabel
│               ├── MineralsLabel
│               └── BackBtn               # "返回"
│
├── WarehousePanel (Control)    # [脚本: warehouse_ui.gd，与WarehouseUI.tscn共用]
│   └── Panel
│       └── VBox
│           ├── ShipInfoBar (Label)      # "护卫舰 | 武:1/1 | 防:1/1"
│           ├── EquippedSection (VBoxContainer)
│           │   ├── EquippedWeaponsTitle: "已装备武器"
│           │   ├── EquippedWeaponsScroll
│           │   │   └── EquippedWeaponsGrid (HBoxContainer)  # 动态填充
│           │   ├── EquippedArmorTitle: "已装备防御"
│           │   └── EquippedArmorScroll
│           │       └── EquippedArmorGrid (HBoxContainer)    # 动态填充
│           ├── InventorySection
│           │   ├── InventoryListLabel: "仓库物品"
│           │   └── InventoryScroll
│           │       └── InventoryGrid (GridContainer)         # 动态填充
│           ├── DetailPanel
│           │   └── DetailHBox
│           │       ├── DetailIcon (Label)    # 品质颜色方块
│           │       └── DetailVBox
│           │           ├── DetailName        # 装备名称（品质色）
│           │           ├── DetailStats        # 详细属性
│           │           ├── DetailDesc        # 描述
│           │           └── SellPriceRow
│           │               └── SellPriceLabel # "出售价: xxx"
│           └── BtnRow
│               ├── EquipBtn      # "装备"
│               ├── UnequipBtn   # "卸下"
│               ├── SellBtn      # "出售"
│               └── BackBtn      # "返回"
│
├── ShipyardPanel (Control)     # [脚本: shipyard_ui.gd，与ShipyardUI.tscn共用]
│   └── Panel
│       └── VBox
│           ├── Title: "船坞 — 舰船升级"
│           ├── HBox
│           │   ├── LeftPanel
│           │   │   └── ShipList (ScrollContainer)
│           │   │       └── VBox              # 动态填充舰船列表
│           │   └── RightPanel
│           │       ├── PreviewTitle: "舰船预览"
│           │       ├── ShipName (Label)      # 舰船名称
│           │       ├── CurrentSlots           # "武器槽: 1 → 升级后: 2"
│           │       ├── Arrow                 # "→"
│           │       ├── UpgradedSlots
│           │       ├── CostInfo              # "升级费用: 800 星币 + 10 低级矿物"
│           │       └── UpgradeBtn             # "升级" / "已满级"
│           └── Footer
│               ├── CoinLabel
│               ├── MineralsLabel
│               └── BackBtn                    # "返回"
│
└── BasePauseMenu (Control)    # [脚本: base_pause_menu.gd]
    ├── Overlay (ColorRect)     # 半透明遮罩
    └── Panel
        └── VBox
            ├── TitleLabel: "基地菜单"
            ├── ContinueBtn    # "返回游戏"
            ├── MainMenuBtn    # "返回主菜单"
            ├── ResetGameBtn  # "重置游戏"
            └── QuitBtn        # "结束游戏"
```

#### BaseScene 导航按钮 → 函数关系

| 按钮 | 触发函数 | 行为 |
|------|---------|------|
| StartBattleBtn | `_on_start_battle()` | 检查武器是否装备，无武器弹出NoWeaponWarning，有武器切换到ShipSelectUI |
| ShopBtn | `_show_shop()` | 显示ShopPanel |
| WarehouseBtn | `_show_warehouse()` | 显示WarehousePanel + `_build_all()` |
| ShipyardBtn | `_show_shipyard()` | 显示ShipyardPanel + `_build_ship_list()` |
| RepairBtn | `_show_repair()` | 显示RepairPanel |
| CraftingBtn | `_show_crafting()` | 显示CraftingPanel |
| StorageBtn | `_show_storage()` | 显示StoragePanel |
| ResetGameBtn | `_on_reset_game_pressed()` | 显示ConfirmResetDialog |
| 对话框 CancelBtn | `_on_cancel_reset()` | 隐藏ConfirmResetDialog |
| 对话框 ConfirmBtn | `_on_confirm_reset()` | 重置游戏状态，更新货币显示 |

---

### 3.6 SettlementScene.tscn — 战斗结算（脚本: `settlement_scene.gd`）

#### 节点访问方式
`@onready`

#### 节点树结构

```
SettlementScene (Control, root)
├── BG (ColorRect)              # rgba(0.03,0.03,0.07,0.98) 深色背景
└── Panel (Panel, 640x680)
    └── VBox
        ├── ResultLabel (Label)      # "任务完成" / "舰船损毁"
        ├── ResultDesc (Label)        # 动态描述文字
        ├── StatsGrid (GridContainer, 2列)
        │   ├── KillsTitle + KillsValue      # 击杀数
        │   ├── LevelTitle + LevelValue       # 最高等级
        │   ├── CoinTitle + CoinValue         # 累计星币
        │   ├── MineralsTitle + MineralsValue # 累计矿物
        │   ├── EarnedTitle + EarnedHBox
        │   │   ├── EarnedCoinValue + EarnedCoinLabel    # 本局获得星币
        │   │   └── EarnedMineralsValue + EarnedMineralsLabel  # 本局获得矿物
        │   └── ShipStatusLabel               # "舰船状态: 良好"
        └── ButtonsHBox
            ├── RetryBtn      # "重新开始" — 修复后进入战斗
            ├── BaseBtn       # "返回基地" — 回到BaseScene
            └── MenuBtn       # "主菜单" — 回到MainMenu
```

#### 按钮列表

| 按钮 | 触发函数 | 行为 |
|------|---------|------|
| RetryBtn | `_on_retry_pressed()` | 若舰船损坏则先维修，切换到GameScene |
| BaseBtn | `_on_base_pressed()` | 切换到BaseScene |
| MenuBtn | `_on_menu_pressed()` | 切换到MainMenu |

---

### 3.7 MainMenu.tscn — 主菜单（脚本: `main_menu.gd`）

#### 节点访问方式
`@onready`

#### 节点树结构

```
MainMenu (Control, root)
├── BG (ColorRect)
└── Panel (Panel)
    └── VBox
        ├── Title: "EVE SURVIVOR"
        ├── Subtitle: "类幸存者 · EVE同人"
        ├── StartBtn: "START MISSION"
        ├── HSeparator
        ├── CoinLabel: "星币: 0"
        ├── MineralsLabel: "矿物: 0低 / 0中 / 0高"
        ├── ShipStatus: "舰船状态: 完好"
        └── RepairsBtn: "REPAIR (500星币)"
```

#### 按钮列表

| 按钮 | 触发函数 | 行为 |
|------|---------|------|
| StartBtn | `_on_start_pressed()` | 切换到CharacterCreate.tscn |
| RepairsBtn | `_on_repair_pressed()` | 调用 `GameState.repair_ship()` |

---

### 3.8 CharacterCreate.tscn — 角色创建（脚本: `character_create.gd`）

#### 节点访问方式
`@onready`

#### 节点树结构

```
CharacterCreate (Control, root)
├── BG (ColorRect)
└── Panel (Panel)
    └── VBox
        ├── Title: "创建角色"
        ├── VersionLabel: "v0.8 · 种族扩展（人类/兽人/植物/硅基）"
        ├── RaceScroll (ScrollContainer)
        │   └── RaceGrid (GridContainer)   # 动态填充种族卡片
        ├── NameRow (HBoxContainer)
        │   ├── NameLabel: "角色名称:"
        │   └── NameEdit (LineEdit)
        └── BtnRow
            ├── BackBtn: "返回"
            └── ConfirmBtn: "确认"（绿色）
```

#### 按钮列表

| 按钮 | 触发函数 | 行为 |
|------|---------|------|
| ConfirmBtn | `_on_confirm()` | 保存种族和名称，切换到BaseScene |
| BackBtn | `_on_back()` | 切换到MainMenu |
| 种族卡片（动态） | `_on_race_card_selected(race_id, card)` | 选中种族 |

---

### 3.9 RaceSelect.tscn — 种族选择（脚本: `race_select.gd`）

#### 节点访问方式
`@onready`

#### 节点树结构

```
RaceSelect (Control, root)
├── BG (ColorRect)
├── Title: "选择种族"
├── HSplit (HSplitContainer)
│   ├── LeftPanel (Panel)
│   │   └── VBox
│   │       ├── Header: "种族列表"
│   │       └── RaceList (VBoxContainer)   # 动态填充种族按钮
│   └── RightPanel (Panel)
│       └── ScrollContainer
│           └── DetailVBox (VBoxContainer)
│               ├── RaceName (Label)        # 种族名称
│               ├── RaceDesc (Label)       # 种族描述
│               ├── AttrsSection (VBoxContainer)
│               │   ├── AttrHP:      "HP: 100"
│               │   ├── AttrShield:  "护盾: 50"
│               │   ├── AttrRegen:   "回复: 4/s"
│               │   ├── AttrSpeed:  "移速: 320"
│               │   ├── AttrDodge:  "闪避: 10%"
│               │   └── AttrCrit:   "暴击: 5%"
│               ├── DefaultWeapon (Label)  # 默认武器
│               └── Talents (Label)        # 天赋效果
└── BottomBar (HBoxContainer)
    ├── BackBtn: "返回主菜单"
    └── ConfirmBtn: "确认选择"（绿色）
```

#### 按钮列表

| 按钮 | 触发函数 | 行为 |
|------|---------|------|
| ConfirmBtn | `_on_confirm_pressed()` | 设置种族，调用 `GameState.on_run_started()`，切换到GameScene |
| BackBtn | `_on_back_pressed()` | 切换到MainMenu |
| 种族按钮（动态） | `_on_race_selected(race_id)` | 更新右侧详情面板 |

---

### 3.10 ShipSelectUI.tscn — 出战舰船选择（脚本: `ship_select_ui.gd`）

#### 节点访问方式
`@onready`

#### 节点树结构

```
ShipSelectUI (Control, root)
├── BG (ColorRect)
└── Panel (PanelContainer)
    └── VBox
        ├── Title: "选择出战舰船"
        ├── ShipList (ScrollContainer)
        │   └── VBox                  # 动态填充，每艘舰船一行含"出发"按钮
        └── BtnRow
            └── CancelBtn: "返回基地"
```

#### 按钮列表

| 按钮 | 触发函数 | 行为 |
|------|---------|------|
| CancelBtn | `_on_cancel()` | 切换到BaseScene |
| 舰船行"出发"（动态） | `_on_ship_selected(ship)` | 保存选中舰船，切换到GameScene |

---

### 3.11 ShopUI.tscn / WarehouseUI.tscn / ShipyardUI.tscn

这三个场景在 BaseScene 中作为子面板嵌入（ShopPanel/WarehousePanel/ShipyardPanel），完全复用对应独立 `.tscn` 的节点结构和脚本。

#### 复用关系

| 独立场景 | 脚本 | BaseScene嵌入名 |
|---------|------|----------------|
| `ShopUI.tscn` | `shop_ui.gd` | `ShopPanel` |
| `WarehouseUI.tscn` | `warehouse_ui.gd` | `WarehousePanel` |
| `ShipyardUI.tscn` | `shipyard_ui.gd` | `ShipyardPanel` |

---

### 3.12 GameScene.tscn — 战斗主场景（脚本: `game_scene.gd`）

#### 节点访问方式
`get_node()` 硬编码路径

#### 节点树结构

```
GameScene (Node2D, root)
│
├── GameManager (Node2D)          # [脚本: game_manager.gd]
│                                 # 管理战斗逻辑、敌人生成、升级系统
├── PlayerRoot (Node2D)           # 玩家飞船挂载点
├── EnemyRoot (Node2D)            # 敌人挂载点
├── BulletRoot (Node2D)           # 弹幕挂载点
├── ExpOrbRoot (Node2D)           # 经验球挂载点
├── DamageRoot (Node2D)            # 伤害数字挂载点
├── ParallaxStarfield (Node2D)    # 视差星空背景
│
└── UIRoot (CanvasLayer)
    ├── HUD (Control)              # 实例化 HUD.tscn
    │                              # HUD通过 @onready 获取路径
    │                              # → `$TopRightAnchor/MainPanel` 等
    ├── UpgradeMenu (Control)      # 实例化 UpgradeMenu.tscn
    │                              # 升级选择界面，初始隐藏
    ├── PauseMenu (Control)        # 实例化 PauseMenu.tscn
    │                              # 暂停菜单，初始隐藏
    └── BossWarning (Control)       # 实例化 BossWarning.tscn
                                    # Boss警告，初始隐藏
```

#### GameScene与结算面板的关系
GameScene 不直接持有 SettlementScene。它通过以下方式注入结算数据：

```gdscript
# game_manager.gd 中
var settlement_scene = load("res://scenes/SettlementScene.tscn")
# 实例化后，通过 get_node_or_null("路径") 设置结算Label的值
settlement.get_node_or_null("Panel/VBox/ResultLabel").text = "任务完成"
settlement.get_node_or_null("Panel/VBox/StatsGrid/KillsValue").text = str(total_kills)
```

---

## 四、UI脚本访问节点的方式分类

| 访问方式 | 说明 | 使用文件 |
|---------|------|---------|
| `@onready var x = $Path` | 场景加载时立即绑定 | `hud.gd`, `pause_menu.gd`, `main_menu.gd`, `race_select.gd`, `base_scene.gd`, `base_pause_menu.gd`, `crafting_table.gd`, `repair_station.gd`, `ship_storage.gd`, `settlement_scene.gd` |
| `find_child("Name", true, false)` | 深度优先搜索子节点 | `shop_ui.gd`, `warehouse_ui.gd`, `shipyard_ui.gd` |
| `get_node_or_null("Path")` | 安全获取，可能为null | `game_scene.gd`, `game_manager.gd`, `hud.gd`, `base_scene.gd` |
| `get_node("Path")` | 直接获取，不安全 | `boss_warning.gd` |
| 动态创建 | `Button.new()` 程序化创建 | 所有有列表/网格的场景（upgrade_menu, shop, warehouse, shipyard, ship_select, race_select, crafting, repair, storage, character_create） |

---

## 五、核心信号系统

| 信号名 | 定义位置 | 接收者 | 行为 |
|--------|---------|--------|------|
| `pause_toggled` | `pause_menu.gd` | GameScene | 暂停/继续游戏 |
| `retreat_requested` | `pause_menu.gd` | GameScene | 撤退结算 |
| `self_destruct_requested` | `pause_menu.gd` | GameScene | 自毁退出 |
| `upgrade_selected(upgrade_id)` | `upgrade_menu.gd` | GameScene | 玩家选择了升级 |
| `currency_changed(currency)` | `game_manager.gd` | HUD | 星币变化时刷新显示 |
| `minerals_changed(minerals)` | `game_manager.gd` | HUD | 矿物变化时刷新显示 |
| `player_dead` | `game_manager.gd` | GameScene | 玩家死亡 |
| `upgrade_requested` | `game_manager.gd` | UpgradeMenu | 请求打开升级菜单 |
| `game_paused(is_paused)` | `game_manager.gd` | 多处 | 暂停状态变化 |
| `game_ended(reason)` | `game_manager.gd` | GameScene | 游戏结束 |
| `reset_game_requested` | `base_pause_menu.gd` | BaseScene | 请求重置游戏 |

---

## 六、GameState 持久化数据结构（与UI绑定）

| GameState字段 | UI读取位置 |
|-------------|-----------|
| `GameState.star_coin` | HUD.info_label, ShopUI, ShipyardUI, BaseScene.Header |
| `GameState.minerals_low/mid/high` | HUD（总和）, ShopUI |
| `GameState.selected_ship_id` | WarehousePanel, ShipyardPanel, CraftingPanel |
| `GameState.selected_race_id` | HUD.race_info_label |
| `GameState.equipped_weapons[ship_id]` | HUD.top_weapon_panel, WarehousePanel |
| `GameState.equipped_armor[ship_id]` | HUD.top_defense_name, WarehousePanel |
| `GameState.equipment_inventory` | CraftingPanel, WarehousePanel |
| `GameState.upgraded_ships[ship_id]` | ShipyardPanel |

---

## 七、HUD面板名称速查表

| 规范名称 | 节点名 | 屏幕位置 | 内容 |
|---------|--------|---------|------|
| **舰船信息面板** | `ShipInfoPanel` | 左下角 | 舰船属性、种族天赋、槽位 |
| **武器栏面板** | `TopWeaponPanel` | 顶部中央 | 武器槽1~6 + 防御槽 |
| **主信息面板** | `MainPanel` | 顶部居中偏右 | HP条、XP条、等级/击杀/星币/连击 |
| **计时器** | `TimerLabel` | 右上角 | 倒计时（仅第一局） |
| **升级列表面板** | `UpgradeListPanel` | 底部居中偏右 | 已获升级效果 |
| **升级选择界面** | `UpgradeMenu` | 全屏居中 | 升级选项（动态按钮） |
| **暂停菜单** | `PauseMenu` | 全屏遮罩 | 继续/撤退/自毁 |
| **Boss警告** | `BossWarning` | 底部横幅 | Boss来袭红色警告 |
| **结算界面** | `SettlementScene` | 全屏 | 战斗结算数据 |
| **主菜单** | `MainMenu` | 全屏 | 开始游戏、货币、维修 |
| **角色创建** | `CharacterCreate` | 全屏 | 种族选择、名称输入 |
| **种族选择** | `RaceSelect` | 全屏 | 种族详情浏览 |
| **基地主界面** | `BaseScene` | 全屏 | 所有基地功能入口 |
| **商店面板** | `ShopPanel` | BaseScene内 | 商品列表、购买出售 |
| **仓库面板** | `WarehousePanel` | BaseScene内 | 装备管理、详情 |
| **造船厂面板** | `ShipyardPanel` | BaseScene内 | 舰船升级解锁 |
| **维修站面板** | `RepairPanel` | BaseScene内 | 舰船维修 |
| **合成面板** | `CraftingPanel` | BaseScene内 | 装备合成、一键合成 |
| **星港面板** | `StoragePanel` | BaseScene内 | 舰船详情查看 |
| **基地暂停菜单** | `BasePauseMenu` | BaseScene内遮罩 | 返回游戏/主菜单/重置/退出 |
