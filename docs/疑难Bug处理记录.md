# EVE Survivor — 疑难 Bug 处理记录

> 记录项目中遇到的不常见、难以复现、或涉及引擎深层机制的 Bug 及其解决方案。

---

## Bug #001：结算界面脚本挂载失败

**影响版本**：v0.8 ~ v0.8
**严重程度**：崩溃（游戏无法进入结算）

### 问题现象

游戏进入结算时崩溃（Fatal），报错：

```
Invalid call. Nonexistent function 'set_settlement_data' in base 'Control'.
Invalid assignment of property or key 'settlement_reason' with value of type 'String' on a base object of type 'Control'.
```

若尝试绕过崩溃让场景显示出来，按钮也会完全无响应——因为 `settlement_scene.gd` 的 `_ready()` 未能执行，按钮的 `pressed` 信号未连接，点击事件穿透到下层游戏场景。


### 根因分析

`SettlementScene.tscn` 通过 UID `uid://5b5sa7yt22yu` 在 `GameScene.tscn` 中 instanced，但节点类型退化成了裸 `Control`。Godot 在以下情况会出现此问题：

1. **脚本路径变化**：`settlement_scene.gd` 路径在项目中途被移动或重命名，但 `.tscn` 中记录的 script path 未同步更新，导致 GDScript 编译缓存无法正确匹配。
2. **.godot 缓存残留**：`import` 文件夹中的编译产物（`.gdc`/`.gdo`）残留，引擎加载了旧的/错误的脚本签名，即使重新打开编辑器也无法自动刷新。
3. **UID 不一致**：`SettlementScene.tscn` 分配了新的 UID，但旧 instanced 节点的引用描述符未更新。

### 修复方案

**方案一（推荐）**：在实例化侧绕过脚本属性访问

不再通过脚本属性/方法操作 `SettlementScene`，改为：

1. 从 `GameScene.tscn` 中移除 `SettlementScene.tscn` 的预加载 instanced 节点。
2. 在 `_show_settlement_screen()` 中动态加载：`load("res://scenes/SettlementScene.tscn").instantiate()`。
3. 通过 `get_node_or_null("Panel/VBox/ResultLabel")` 获取子节点，**直接操作 Label.text / Button.disabled**，完全不依赖脚本属性。
4. 按钮信号由 `GameScene` 侧手动连接，不依赖 `settlement_scene.gd` 的 `_ready()`。

关键代码：

```gdscript
var settlement = load("res://scenes/SettlementScene.tscn").instantiate()
settlement.process_mode = Node.PROCESS_MODE_ALWAYS

var result_label = settlement.get_node_or_null("Panel/VBox/ResultLabel")
if result_label:
    result_label.text = "任务完成"

var retry_btn = settlement.get_node_or_null("Panel/VBox/ButtonsHBox/RetryBtn")
if retry_btn:
    retry_btn.pressed.connect(_on_settlement_retry)

$UIRoot.add_child(settlement)
```

**方案二**：彻底清除缓存

1. 关闭 Godot 编辑器。
2. 删除项目根目录下的 `.godot` 文件夹。
3. 删除 `import` 文件夹。
4. 重新打开 Godot，引擎重新导入所有资源并生成新的 UID/编译缓存。

### 预防措施

- 修改脚本路径后，立即在 Godot 编辑器中检查 `.tscn` 的 script 引用是否同步。
- 脚本变更（新增方法/属性）后运行报错，优先尝试清除缓存。
- 重要节点使用 `get_node_or_null()` 并加空检查，避免单点故障导致崩溃。

---

## Bug #002：种族卡片鼠标点击被拦截

**影响版本**：v0.9
**严重程度**：功能失效（点击无响应）

### 问题现象

在角色创建界面（`CharacterCreate`）中，种族卡片高亮正常，但鼠标点击种族卡片时按钮无反应。视觉反馈正常（高亮、选中状态切换），但点击事件被拦截，无法切换种族。

### 根因分析

在 `_create_race_card()` 中，卡片最后添加了一个透明的 `mouse_filter_controller`：

```gdscript
var mouse_filter_controller = Control.new()
mouse_filter_controller.mouse_filter = Control.MOUSE_FILTER_STOP
card.add_child(mouse_filter_controller)
```

**关键问题**：在 Godot 的节点树中，最后添加的子节点在视觉最上层（z-order）。这个 `mouse_filter_controller` 覆盖在按钮上方，`MOUSE_FILTER_STOP` 导致所有鼠标事件在到达按钮前就被它消费掉了。

这不是 `settlement_scene.gd` 那种"节点类型退化"的问题，而是更直接的 UI 遮挡——一个透明 Control 拦截了所有鼠标事件。

### 修复方案

删除 `mouse_filter_controller`，改用 `PanelContainer` 的 `gui_input` 信号来处理整个卡片的鼠标点击。当检测到左键点击时，手动触发按钮的 `pressed` 信号：

```gdscript
# 删除：
# var mouse_filter_controller = Control.new()
# mouse_filter_controller.mouse_filter = Control.MOUSE_FILTER_STOP
# card.add_child(mouse_filter_controller)

# 新增：连接 gui_input 信号
card.gui_input.connect(_on_card_gui_input.bind(card))

# 新增处理器：
func _on_card_gui_input(event: InputEvent, card: Control) -> void:
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var btn: Button = card.get_meta("button") as Button
			if btn and not btn.disabled:
				btn.emit_signal("pressed")
```

### 预防措施

- 不要用空 Control + `MOUSE_FILTER_STOP` 来"拦截"鼠标事件，这会导致事件无法传递给下层控件。
- 如需处理整个卡片的点击，直接用 `gui_input` 信号。
- 如果确实需要阻止事件穿透到下层，应使用 `MOUSE_FILTER_PASS` 并显式处理事件，而不是单纯"停在当前节点"。

---

## Bug #003：仓库界面装备列表不显示

**影响版本**：v1.0
**严重程度**：功能失效（界面可打开但内容为空）

### 问题现象

从基地（BaseScene）点击"仓库"按钮后，WarehouseUI 面板正常弹出，标题栏和按钮正常显示，但"已装备"和"仓库库存"两个 GridContainer 区域完全空白——既不显示装备按钮，也不显示"（无已装备）"/"（仓库为空）"的提示文字。

### 根因分析

核心问题：**节点的布局尺寸为 0，被父节点完全裁切**。

`WarehouseUI.tscn` 的设计经历了以下演变：

1. **初始版本**：WarehousePanel 作为 BaseScene 的直接子节点，在 `BaseScene.tscn` 中预加载实例化。它在 BaseScene 的 `VBoxContainer` 中有明确的 layout 约束（`size_flags_vertical = 3`），自然被撑开为有效尺寸。

2. **重构后**：WarehouseUI 改为独立场景 `WarehouseUI.tscn`，通过 `add_child` 动态挂载到 BaseScene。此时 WarehouseUI 场景的根节点 `Control` 的 `anchors_preset = 15`（全屏锚点），但**没有任何额外的尺寸约束**。当它作为独立 `.tscn` 加载时，Godot 根据 window size 自动分配尺寸；但当它作为子节点 `add_child` 到 BaseScene 的 Control 下时——BaseScene 本身没有预设尺寸被子节点撑开——WarehouseUI 的实际布局尺寸为 0。所有子节点（ScrollContainer → GridContainer → Button）全部被裁切掉。

这不是数据流问题，不是 `_build_all` 没有被调用——`_deferred_init` 中 `_build_all()` 确实执行了，所有数据加载正常。问题纯粹是**渲染/布局层级**的尺寸问题。

### 修复方案

为 ScrollContainer 和 GridContainer 显式设置 `custom_minimum_size`，确保即使父节点尺寸为 0，内容区域也有最小高度：

1. `InventoryScroll`：`custom_minimum_size = Vector2(0, 176)`
2. `InventoryGrid`：`custom_minimum_size = Vector2(0, 160)`
3. `EquippedScroll`：`custom_minimum_size = Vector2(0, 176)`

同时，在 `base_scene.gd` 的 `_show_warehouse()` 中，scene 已存在时重新显示也需要调用 `_build_all()` 刷新数据：

```gdscript
func _show_warehouse() -> void:
    if current_panel and is_instance_valid(current_panel):
        current_panel.visible = false
    if warehouse_scene_instance and is_instance_valid(warehouse_scene_instance):
        warehouse_scene_instance.visible = true
        current_panel = warehouse_scene_instance
        if warehouse_scene_instance.has_method("_build_all"):
            warehouse_scene_instance._build_all()  # 关键：再次打开时刷新数据
    else:
        var wh_scene = load("res://scenes/WarehouseUI.tscn")
        if wh_scene:
            var inst = wh_scene.instantiate()
            add_child(inst)
            warehouse_scene_instance = inst
            inst.visible = true
            current_panel = inst
```

### 预防措施

- 动态加载的子场景，其根节点 Control **不应仅依赖 anchors_preset**，需要额外设置 `custom_minimum_size` 或其他尺寸约束。
- UI 不显示时，调试顺序应为：节点存在？→ visible 为 true？→ **尺寸 > 0？** → **父节点尺寸 > 0？** → 有没有被裁切？——尺寸检查应排在数据流检查之前。
- 再次打开已有 scene 时，记得调用刷新方法，因为 `visible = true` 不会重新执行 `_ready`。

---

## Bug #004：仓库库存 Grid 被裁切不显示

**影响版本**：v1.1
**严重程度**：功能失效（界面可打开但内容为空）

### 问题现象

CraftingPanel 的装备列表正常显示，但 WarehousePanel（物品仓库）的"库存"和"已装备"两个 GridContainer 区域完全空白，按钮和数据都存在但不渲染。

### 根因分析

**核心问题**：GridContainer 缺少 `custom_minimum_size`，父容器尺寸不足时内容被裁切。

CraftingPanel 的 `InventoryGrid` 设置了 `custom_minimum_size = Vector2(0, 200)`，因此正常显示；而 WarehousePanel 的两个 Grid（`WarehousePanel/Panel/VBox/HBox/LeftPanel/InventoryScroll/InventoryGrid` 和 `WarehousePanel/Panel/VBox/HBox/RightPanel/EquippedScroll/EquippedGrid`）均无此属性，在父容器高度不足时被裁切到 0。

这不是数据流问题——`_build_inventory()` 和 `_build_equipped_list()` 确实执行了，Button 节点也正确创建并 `add_child` 了。

### 修复方案

为 WarehousePanel 的两个 GridContainer 添加 `custom_minimum_size`：

1. `WarehousePanel/Panel/VBox/HBox/LeftPanel/InventoryScroll/InventoryGrid`：`custom_minimum_size = Vector2(0, 200)`
2. `WarehousePanel/Panel/VBox/HBox/RightPanel/EquippedScroll/EquippedGrid`：`custom_minimum_size = Vector2(0, 200)`

### 预防措施

- **所有动态填充内容的 GridContainer / VBoxContainer / ScrollContainer 都应设置 `custom_minimum_size`**，而非依赖父容器自动撑开。
- 当同一类 UI 组件（仓库 vs 合成）的某个实例不显示时，首先对比两者在 `.tscn` 中的 layout 属性差异。

---

## Bug #005：战斗HUD右下角升级列表不显示

**影响版本**：v1.1
**严重程度**：功能失效（界面完全不可见）

### 问题现象

战斗场景中，右下角的"已获升级"面板（UpgradeListPanel）完全看不到。玩家拿到升级后，面板既无标题也无内容。

### 根因分析

本次调试历时较长，共排查了多层原因：

**1. 错误的 `anchors_preset` 锚点**

`BottomRightAnchor` 节点使用了 `anchors_preset = 2`，在 Godot 中代表 **bottom-left（左下角锚点）**——即锁定在屏幕**左边**。正确的应该是 `anchors_preset = 1`（bottom-right，右下角锚点）。

修复前坐标：`global_pos=(-310.0, 780.0)` → 面板跑到了屏幕最左边（viewport width=1920，左边 = x < 0）。
修复后坐标：`global_pos=(1610.0, 780.0)` → 面板正确地位于右下角。

```ini
# 错误写法（anchors_preset=2 = bottom-left，锁定屏幕左边）：
anchors_preset = 2
offset_left = -310.0
# 结果：global_pos = (-310, 780)，在屏幕左侧之外

# 正确写法（anchors_preset=1 = bottom-right，锁定屏幕右边）：
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -310.0
offset_right = -10.0
# 结果：global_pos = (1610, 780)，在屏幕右下角
```

**2. 中途增加了不必要的设计复杂度**

初次实现时引入了 `ScrollContainer` 作为中间层级，而 `ScrollContainer` 内部的 `VBoxContainer` 初始内容只有 `TitleLabel` 和 `Divider` 两个装饰节点（通过 `if child is Label and child.name != "TitleLabel"` 跳过）。当 `VBoxContainer` 内容高度为 0 时，`ScrollContainer` 的计算高度也为 0，导致整个面板不可见。即使后续移除了 ScrollContainer，第一个错误（错误的锚点）仍然隐藏了面板，导致其他修复尝试均告失败。

**3. `_last_upgrade_snapshot` 逻辑干扰调试**

原始代码中存在一个快照比较优化逻辑，在 `apply_upgrade` 调用 `_notify_hud_update()` 后，同帧内的 `_process` 会因为快照已匹配而提前 return，干扰了对面板实际渲染状态的判断。已移除该优化。

### 修复方案

1. 将 `BottomRightAnchor` 的 `anchors_preset` 从 `2`（bottom-left）改为 `1`（bottom-right），确保面板锚定在屏幕右侧。
2. 移除 `ScrollContainer` 中间层级，`VBoxContainer` 直接作为 `PanelContainer` 的子节点。
3. 为 `UpgradeListPanel` 设置 `custom_minimum_size = Vector2(300, 30)`，确保面板有最小尺寸。
4. 移除 `_last_upgrade_snapshot` 快照比较逻辑，每帧正常更新。

### 调试方法

通过在 `_update_upgrade_list_display()` 中打印完整的尺寸链来定位问题：

```gdscript
var bra = $BottomRightAnchor
print("  BottomRightAnchor global_pos=", bra.global_position, " size=", bra.size)
print("  UpgradeListPanel global_rect=", upgrade_panel.get_global_rect(), " visible=", upgrade_panel.visible)
var vbox = upgrade_list_vbox
print("  UpgradeListVBox size=", vbox.size, " min_size=", vbox.custom_minimum_size)
for ci in range(2, vbox.get_child_count()):
    var child = vbox.get_child(ci)
    print("    child[", ci, "]=", child.name, " visible=", child.visible, " size=", child.size)
```

### 预防措施

- **复制 UI 节点时务必检查 `anchors_preset`**：锚点决定面板在屏幕上的实际位置，preset=2（bottom-left）和 preset=1（bottom-right）在视觉上差异极大但命名容易混淆。
- **UI 组件复制粘贴后，逐项核对 layout 属性**：尤其注意 `anchors_preset`、`offset_*`、`size_flags_*`、`custom_minimum_size`。
- **调试 UI 不可见问题时，永远先打印 `global_position` 和 `size`**：Bug #003 和 #004 的经验表明，节点存在且 `visible=true` 并不代表实际可见，尺寸为 0 是最常见原因。
- **使用控制变量法逐步排查**：当多个潜在问题同时存在时（如本例的锚点错误 + ScrollContainer 结构），应先修复最基础的布局问题，再验证其他修复是否有效。
