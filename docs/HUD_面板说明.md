# HUD 面板说明文档

> 战斗场景 (`scenes/GameScene.tscn`) 中所有 HUD 面板的完整节点层级与用途说明。

---

## 场景结构总览

```
GameScene (CanvasLayer: UIRoot)
├── HUD                    # 主 HUD 场景 (scenes/HUD.tscn)
├── UpgradeMenu            # 升级选择菜单 (scenes/UpgradeMenu.tscn)
├── PauseMenu              # 暂停菜单 (scenes/PauseMenu.tscn)
└── BossWarning             # Boss 来袭警告 (scenes/BossWarning.tscn)
```

---

## 1. HUD 主面板 (`scenes/HUD.tscn`)

根节点: `HUD` (Control)
脚本: `scripts/hud.gd`

---

### 1.1 左下角 — 玩家状态面板 (`ShipInfoPanel`)

路径: `HUD / ShipInfoPanel / ShipInfoVBox`

显示玩家飞船的生命值、护盾、种族和装备槽位信息。

| 节点名 | 类型 | 说明 |
|---|---|---|
| `ShipTitle` | Label | 飞船名称 (如 "NOVA STRIKER") |
| `HPRow` | HBoxContainer | HP 行 |
| `├── HPLabel` | Label | 显示 "HP" |
| `└── HPBar` | ProgressBar | HP 进度条 (0~max) |
| `ShieldRow` | HBoxContainer | 护盾行 |
| `├── ShieldLabel` | Label | 显示护盾数值 |
| `└── ShieldBar` | ProgressBar | 护盾进度条 (0~max) |
| `Divider` | HSeparator | 分隔线 |
| `RaceInfoLabel` | Label | 种族信息 (如 "种族: 人类") |
| `ShipSlotsLabel` | Label | 装备槽位占用情况 (如 "武:0/2 \| 防:0/1") |

---

### 1.2 顶部居中 — 装备槽位面板 (`TopWeaponPanel`)

路径: `HUD / TopCenterAnchor / TopWeaponPanel / TopWeaponHBox`

显示当前已装备的武器和防御道具。

#### 武器槽 (共 6 个)

| 节点名 | 类型 | 说明 |
|---|---|---|
| `WeaponSlot1` | PanelContainer | 武器槽位 1 |
| `WeaponSlot2` | PanelContainer | 武器槽位 2 |
| `WeaponSlot3` | PanelContainer | 武器槽位 3 |
| `WeaponSlot4` | PanelContainer | 武器槽位 4 |
| `WeaponSlot5` | PanelContainer | 武器槽位 5 |
| `WeaponSlot6` | PanelContainer | 武器槽位 6 |

每个武器槽内部结构:
```
WeaponSlotX / WeaponSlotXVBox
├── TypeLabel  (Label)  — 显示 "[武器]"
└── Name       (Label)  — 显示武器名称 (空槽显示为空)
```

#### 防御槽 (共 5 个)

| 节点名 | 类型 | 说明 |
|---|---|---|
| `DefenseSlot1` | PanelContainer | 防御槽位 1 |
| `DefenseSlot2` | PanelContainer | 防御槽位 2 |
| `DefenseSlot3` | PanelContainer | 防御槽位 3 |
| `DefenseSlot4` | PanelContainer | 防御槽位 4 |
| `DefenseSlot5` | PanelContainer | 防御槽位 5 |

每个防御槽内部结构:
```
DefenseSlotX / DefenseSlotXVBox
├── TypeLabel  (Label)  — 显示 "[防御]"
└── Name       (Label)  — 显示防御道具名称 (空槽显示 "空槽位")
```

---

### 1.3 底部居中 — XP 面板 (`MainPanel`)

路径: `HUD / BottomCenterAnchor / MainPanel / VBox`

显示玩家经验值和等级。

| 节点名 | 类型 | 说明 |
|---|---|---|
| `XPRow` | HBoxContainer | XP 行 |
| `├── XPLabel` | Label | 显示 "XP" |
| `├── XPBar` | ProgressBar | XP 进度条 (0~max) |
| `└── LevelLabel` | Label | 显示 "Lv.X" |

---

### 1.4 右上角 — 状态信息面板 (`TopRightAnchor`)

路径: `HUD / TopRightAnchor / StatusVBox`

显示计时器、金币获取提示、综合信息和连击数。

| 节点名 | 类型 | 说明 |
|---|---|---|
| `TimerLabel` | Label | 游戏倒计时/已用时间 (格式如 "05:00" 或 "+01:23") |
| `CoinGainLabel` | Label | 击杀金币获取提示 (如 "+10") |
| `InfoLabel` | Label | 综合信息 (如 "Level: 1 \| Kills: 0 \| 星币: 0") |
| `ComboLabel` | Label | 连击数提示 (战斗连击 >= 3 时显示，如 "x5 COMBO!") |

---

### 1.5 右下角 — 升级列表面板 (`UpgradeListPanel`)

路径: `HUD / BottomRightAnchor / UpgradeListPanel / UpgradeListVBox`

显示本局已获得的升级效果列表。

| 节点名 | 类型 | 说明 |
|---|---|---|
| `TitleLabel` | Label | 标题 "已获升级" |
| `Divider` | HSeparator | 分隔线 |
| 动态升级项 | Label | 每获得一个新升级动态添加一行 |

---

### 1.6 虚拟摇杆 (`VirtualJoystick`)

路径: `HUD / VirtualJoystick`

| 节点名 | 类型 | 说明 |
|---|---|---|
| `VirtualJoystick` | (VirtualJoystick) | 移动虚拟摇杆，左下角区域，支持自动隐藏 |

---

## 2. 升级选择菜单 (`scenes/UpgradeMenu.tscn`)

路径: `GameScene / UIRoot / UpgradeMenu`

升级选择界面，升级时弹出供玩家选择。

| 节点名 | 类型 | 说明 |
|---|---|---|
| `ColorRect` | ColorRect | 半透明背景遮罩 |
| `CenterContainer` | CenterContainer | 居中容器 |
| `└── UpgradePanel` | PanelContainer | 升级面板 |
| `    └── VBox` | VBoxContainer | 垂直排列 |
| `        └── TitleLabel` | Label | 标题 "选择升级" |

---

## 3. 暂停菜单 (`scenes/PauseMenu.tscn`)

路径: `GameScene / UIRoot / PauseMenu`

游戏暂停时显示的菜单界面。

| 节点名 | 类型 | 说明 |
|---|---|---|
| `Overlay` | ColorRect | 全屏深色遮罩 |
| `Panel` | Panel | 菜单面板 |
| `└── VBox` | VBoxContainer | 垂直排列 |
| `    ├── TitleLabel` | Label | "暂停" 标题 |
| `    ├── ContinueBtn` | Button | 继续游戏按钮 |
| `    ├── RetreatBtn` | Button | 撤退/返回主菜单按钮 |
| `    ├── SelfDestructBtn` | Button | 自爆按钮 |
| `    ├── LootSectionLabel` | Label | "战利品" 标签 |
| `    └── LootScroll` | ScrollContainer | 战利品滚动列表 |
| `        └── LootContainer` | VBoxContainer | 战利品条目容器 |

---

## 4. Boss 来袭警告 (`scenes/BossWarning.tscn`)

路径: `GameScene / UIRoot / BossWarning`

Boss 出现前的警告提示。

| 节点名 | 类型 | 说明 |
|---|---|---|
| `Panel` | Panel | 警告面板 |
| `└── Label` | Label | 警告文字 (如 "BOSS INCOMING") |

---

## 面板定位汇总

| 面板名 | 锚点位置 | 区域 |
|---|---|---|
| `ShipInfoPanel` | 左下 | 左下角 — HP/护盾条 + 种族 + 槽位 |
| `TopWeaponPanel` | 顶部居中 | 顶部中央 — 武器/防御槽 |
| `MainPanel` | 底部居中 | 底部中央 — XP 条 + 等级 |
| `StatusVBox` | 右上 | 右上角 — 计时器 + 金币 + 信息 + 连击 |
| `UpgradeListPanel` | 右下 | 右下角 — 已获升级列表 |
| `VirtualJoystick` | 左下 | 左下角 (摇杆) |
| `UpgradeMenu` | 全屏居中 | 覆盖层 |
| `PauseMenu` | 全屏居中 | 覆盖层 |
| `BossWarning` | 全屏居中 | 覆盖层 |

---

## 相关文件

| 文件 | 说明 |
|---|---|
| `scenes/HUD.tscn` | HUD 场景定义 |
| `scenes/GameScene.tscn` | 战斗场景入口，实例化各 UI 场景 |
| `scripts/hud.gd` | HUD 逻辑脚本 |
| `scenes/UpgradeMenu.tscn` | 升级菜单场景 |
| `scenes/PauseMenu.tscn` | 暂停菜单场景 |
| `scenes/BossWarning.tscn` | Boss 警告场景 |
