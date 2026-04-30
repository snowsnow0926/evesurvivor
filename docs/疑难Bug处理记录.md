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
