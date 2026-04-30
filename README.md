# EVE Survivor

EVE同人 · 类幸存者游戏 | Godot 4.6 + GDScript

## 项目结构

```
类幸存者eve同人/
├── project.godot          # Godot 项目配置
├── assets/
│   └── icon.svg           # 项目图标
├── scenes/
│   ├── MainMenu.tscn      # 主菜单
│   ├── GameScene.tscn     # 游戏场景（整合场景）
│   ├── SettlementScene.tscn  # 结算界面
│   ├── Player.tscn        # 玩家护卫舰
│   ├── EnemyMelee.tscn     # 近战敌人
│   ├── Missile.tscn        # 导弹
│   ├── ExpOrb.tscn         # 经验球
│   ├── HUD.tscn            # HUD（HP/盾/资源/经验）
│   ├── UpgradeMenu.tscn     # 升级选择界面
│   └── PauseMenu.tscn       # 暂停菜单
└── scripts/
    ├── game_state.gd       # 全局状态（Autoload，星币/矿物/舰船状态）
    ├── game_scene.gd       # 游戏场景主控
    ├── game_manager.gd     # 核心游戏逻辑（敌人生成/难度/升级触发）
    ├── player.gd           # 玩家控制（WASD移动 + 自动索敌）
    ├── enemy_melee.gd      # 近战敌人AI
    ├── missile.gd          # 导弹（方向发射）
    ├── exp_orb.gd          # 经验球（浮动动画）
    ├── hud.gd              # HUD 显示
    ├── upgrade_menu.gd     # 三选一升级界面
    ├── pause_menu.gd       # 暂停/撤离菜单
    ├── main_menu.gd        # 主菜单
    └── settlement_scene.gd # 结算界面
```

## 运行方式

1. 用 Godot 4.6.x 打开项目根目录
2. 按 `F6` 或点击"运行"启动（自动进入主菜单）

## 操作说明

| 操作 | 按键 |
|------|------|
| 移动 | WASD |
| 暂停 | ESC |

## 游戏流程

1. **主菜单** → 点击 START MISSION 开始
2. **战斗中** → WASD 移动，导弹自动索敌射击
3. **升级** → 经验满弹出三选一升级
4. **阵亡** → 结算 50% 资源，舰船损坏 → 维修后重开
5. **撤离** → ESC → 撤离，结算 100% 资源

## MVP 设计要点

- 玩家护卫舰：WASD 移动，导弹自动索敌，护盾始终回充
- 敌人：近战冲脸，每20击杀递增难度
- 升级池：6种（射速/伤害/盾上限/移速/弹幕/生命回复）
- 资源：星币（货币）+ 矿物 + 维修系统
- 闯关模式：保留设计，MVP 先不做
