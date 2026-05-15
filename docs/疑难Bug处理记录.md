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

---

## Bug #006：导出后美术素材（动态加载图片）不显示

**影响版本**：v1.0 ~ v2.1
**严重程度**：功能失效（界面可打开但图片空白）

### 问题现象

在 Godot 编辑器中 F6 运行游戏，关卡选择界面（`ChapterSelectUI.tscn`）的背景图和关卡卡片图片均正常显示。但使用导出模板生成 `.exe` 后运行，背景图正常，关卡卡片图片完全消失。

### 根因分析

**核心问题：编辑器路径 vs 打包资源路径解析不一致。**

场景 `.tscn` 中的图片引用通过 `ExtResource` 直接声明，在编辑器环境和导出环境中都能被 Godot 资源管理系统正确处理。

关卡卡片的图片是通过代码动态加载的：

```gdscript
# 错误写法（Bug 中的原始代码）
var img := Image.new()
img.load(img_path)  # "res://assets/base/menu/chapter_cards/chapter_01_card.png"
tex_rect.texture = ImageTexture.create_from_image(img)
```

`Image.load()` 是 Godot 3 的旧 API，在 Godot 4 + 打包导出场景下，虚拟文件系统路径（`res://`）解析行为与编辑器内运行不一致。当资源被打包进 `.pck` 文件后，`Image.load("res://...")` 无法正确解析路径，导致图片加载失败而静默跳过。

即使改用 `load()` 也无法在所有导出环境下保证可靠加载。

### 最终修复方案

**彻底放弃动态加载，改用静态节点引用图片。**

1. 在 `ChapterSelectUI.tscn` 中预置 6 个卡片节点（Card1 ~ Card6），每个卡片包含 `TextureRect`、`VBoxContainer`、`Label`、`Button`。
2. 每个卡片的 `TextureRect` 通过 `ExtResource` 直接引用对应的图片：
   - Card1 → `chapter_01_card.png`
   - Card2 → `chapter_02_card.png`
   - ... 以此类推到 chapter_06。
3. 脚本不再动态创建节点和加载图片，只负责从静态节点读取并配置文字、颜色、按钮信号。

关键改动——脚本中通过固定路径访问静态节点：

```gdscript
const CARD_PATHS := [
    "Panel/VBox/ScrollContainer/ChapterContainer/Card1",
    "Panel/VBox/ScrollContainer/ChapterContainer/Card2",
    # ... 共 6 个
]

func _load_chapters() -> void:
    var chapters := StageData.get_all_chapters()
    for i in range(min(chapters.size(), CARD_PATHS.size())):
        var chapter: StageData.ChapterInfo = chapters[i]
        var card: Panel = get_node(CARD_PATHS[i])
        var is_unlocked: bool = GameState.is_chapter_unlocked(chapter.id)
        _configure_card(card, chapter, is_unlocked)
```

图片引用通过 `.tscn` 的 `ExtResource` 声明，脚本只操作文字/颜色/信号，完全不处理图片加载逻辑。

### 受影响范围（其他可能存在相同问题的美术素材）

**所有通过代码动态加载图片资源的地方都需要检查**，包括但不限于：

- 动态生成的卡牌图片（如种族卡、装备图标、道具图标）
- 运行时从文件路径拼接加载的图片（如按 ID 命名的皮肤/外观资源）
- 通过 `Image.load()` / `load("res://...")` 加载的 `.png` / `.jpg` / `.webp` 纹理
- 任何在 `.tscn` 中**不是**通过 `ExtResource` 直接引用的图片资源

### 预防措施

- **美术素材必须通过 `.tscn` 中的 `ExtResource` 直接引用**，不要在脚本中动态加载纹理文件路径。
- 导出测试是必须的——编辑器正常运行不能作为导出后也正常的依据。
- 如果必须动态创建节点，可以先在 `.tscn` 中预置节点、隐藏备用，运行时通过 `get_node()` 获取并显示，避免在代码里 `load()` 纹理路径。

---

## Bug #007：隐藏字符导致 Godot 解析错误

**影响版本**：任意版本
**严重程度**：编译错误（脚本完全无法加载）
**调试难度**：高（肉眼无法发现，标准编码检查也无法察觉）

### 问题现象

Godot 4 报错，但报错位置和代码看起来完全正常：

```
ERROR: res://scripts/settings_manager.gd:27 - Parse Error: Expected statement, found "else" instead.
ERROR: res://scripts/main_menu.gd:117 - Parse Error: Cannot infer the type of "ui" variable because the value doesn't have a set type.
ERROR: res://scripts/pause_menu.gd:65 - Parse Error: Cannot infer the type of "ui" variable because the value doesn't have a set type.
```

行27是 `else:`，肉眼看起来格式完全正确。行117和行65的 `load(...).instantiate()` 链式调用看起来也没问题。

### 根因分析

**问题出在前一行语句的末尾混入了不可见字符。**

GDScript 的语句以换行符分隔，如果上一行（如 line 26 `_apply_to_sound_manager()`）末尾有零宽字符（如零宽空格 U+200B、零宽不换行空格 U+FEFF、或 UTF-16 代理对残留），Godot 解析器会认为该语句尚未结束，从而把下一行的 `else:` 当作同一语句的一部分，报 `Expected statement, found "else"`。

`null` 字节检测（BOM 检测）**无法**发现这类字符，因为零宽字符不是 null，它们的字节是合法 UTF-8 序列。PowerShell 的 `Get-Content -Encoding UTF8` 读取时也会自动过滤大多数零宽字符，导致即使逐行读取也看不到异常。

对于链式调用 `.instantiate()` 的类型推断报错，情况类似——Godot 4 对 `Variant` 值的类型推断比想象中更严格，`load(...).instantiate()` 返回 `Variant`（因为 `load` 返回的是 `Resource` 而非 `PackedScene`），`:=` 推断不出具体类型。

### 修复方案

**对于隐藏字符问题**——最干净的修复是重写相关代码块，消除 `else` 块对缩进的依赖：

```gdscript
# 原始（有问题的结构，else: 依赖于精确的缩进/行边界）
if err == OK:
    # ... 赋值
    _apply_to_sound_manager()
else:  # ← 上一行末尾可能有隐藏字符，导致解析器认为 else: 不是独立语句
    # ... 默认值

# 修复后（用 return 早期返回，消除 else: 依赖）
if err == OK:
    # ... 赋值
    _apply_to_sound_manager()
    return  # 早期返回，替代 else:
# 默认值...
```

**对于链式调用类型推断问题**——显式声明类型：

```gdscript
# 原始（类型推断失败）
var ui := load("res://scenes/SettingsUI.tscn").instantiate()

# 修复后（显式两步声明）
var scene: PackedScene = load("res://scenes/SettingsUI.tscn")
var ui: Control = scene.instantiate()
```

### 排查清单

当遇到"代码看起来完全正常但 Godot 报解析错误"时：

1. **不要浪费时间排查文件路径、编码格式、正反斜杠**——Windows 文件系统正反斜杠等效，不是问题。
2. **检查正上方一行末尾是否有隐藏字符**：在前一行末尾打断点，或用十六进制查看器检查上一行最后一个可显示字符的字节之后是否有 `0xE2 0x80 0x8B`（U+200B 零宽空格）、`0xEF 0xBB 0xBF`（BOM）、`0xEF 0xBF 0xBD`（替换字符 U+FFFD）等。
3. **最直接的修复方式**：重写相关代码块，用 `return` 替代 `else:`，用显式类型声明替代链式类型推断。
4. **PowerShell 检查不可见字符的可靠方式**：

```powershell
# 读取文件的原始字节，逐字节排查换行符之间的内容
$b = [System.IO.File]::ReadAllBytes("path/to/file.gd")
$lines = [System.Text.Encoding]::UTF8.GetString($b).Split("`n")
# 检查第 N 行末尾是否有非空白字节
$line = $lines[$N - 1]  # GDScript 行号从1开始
$lineBytes = [System.Text.Encoding]::UTF8.GetBytes($line)
# 零宽字符范围：0xE2 0x80 0x8B (U+200B), 0xE2 0x80 0x8C (U+200C),
#               0xE2 0x80 0x8D (U+200D), 0xE2 0x80 0x8E (U+200E),
#               0xE2 0x80 0x8F (U+200F), 0xEF 0xBB 0xBF (U+FEFF BOM)
```

### 预防措施

- 养成习惯：用编辑器保存 GDScript 文件时，确保使用**纯 UTF-8（无 BOM）** 编码。
- 避免在行末添加多余的空格或不可见字符。
- 使用 `:=` 声明变量时，**不要链式调用** `.instantiate()`，拆成两步并显式声明类型。

---

### 误判记录（Agent 排查教训）

**误判：正斜杠/反斜杠路径不一致导致 Godot 无法找到脚本。**

实际情况：Windows 文件系统中，正斜杠 `/` 和反斜杠 `\` 完全等效（Windows 内核层面都解析为 `\`）。Glob 工具在不同上下文中可能以不同风格报告同一文件路径（如 `scripts\xxx.gd` vs `scripts/xxx.gd`），但这是工具报告格式的差异，**不是文件系统的真实差异**。Git 状态里看到两个路径写法也并不意味着真的存在两个文件——在 Windows 上它们就是同一个文件。

**排查教训**：遇到文件路径类问题时，先确认文件是否真的存在（`Test-Path`），再确认文件字节内容（`ReadAllBytes`），而不是被工具报告的路径格式所迷惑。Windows 上正反斜杠的问题几乎可以**直接排除**，除非是在生成跨平台字符串（如写入 `.tscn` 内部引用）时才需要关注。
