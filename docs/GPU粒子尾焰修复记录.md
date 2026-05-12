# GPU 粒子尾焰修复记录

## 错误总结

本次 `ship_exhaust.gd` 的实现中，犯了大量低级错误，按严重程度排列如下：

---

### 1. 架构错误（最严重）

**错误：用代码 new() 创建 GPUParticles2D，而不是在场景编辑器里添加节点。**

| 做法 | 优点 | 缺点 |
|------|------|------|
| 编辑器添加节点 | 编辑器实时预览、属性全可见、场景保存 | 无 |
| 代码 new() 创建 | 动态配置参数 | 无编辑器预览、属性不可见、失去检查器支持 |

正确的做法是：
1. 在场景编辑器里给 Ship 节点直接添加 `GPUParticles2D` 子节点
2. 在 `ship_exhaust.gd` 里直接 `@onready var _particles: GPUParticles2D = $ShipExhaustParticles`
3. 所有粒子参数在检查器里直接配置，不需要任何 setter

---

### 2. API 命名错误

| 我写的（错误） | 正确属性名 |
|---|---|
| `_particles.flag_align_y = false` | `_process_mat.set_particle_flag(PARTICLE_FLAG_ALIGN_Y_TO_VELOCITY, false)` |
| `_process_mat.scale_amount_min` | `_process_mat.scale_min` |
| `_process_mat.scale_amount_max` | `_process_mat.scale_max` |
| `PARTICLE_FLAG_ALIGN_Y` | `PARTICLE_FLAG_ALIGN_Y_TO_VELOCITY` |

---

### 3. 类型错误

| 我写的（错误） | 正确类型 |
|---|---|
| `_process_mat.direction = Vector2(0, -1)` | `Vector3(0, -1, 0)` |
| `_process_mat.gravity = Vector2.ZERO` | `Vector3.ZERO` |

**原因**：Godot 4 的 `ParticleProcessMaterial` 是 3D 物理材料，`direction` 和 `gravity` 都是 `Vector3`，没有 2D 版本。2D 粒子（GPUParticles2D）用的仍是同一个 material，只是 Z 轴默认折叠到 2D 平面。

---

### 4. 根本原因

每次都在不知道 Godot API 确切属性名的情况下**凭感觉猜测**，导致：
- `scale_amount_min` —— 想象出来的属性
- `flag_align_y` —— 想象出来的直接属性
- `direction` 用 `Vector2` —— 以为 2D 就用 2D 向量

---

### 5. 正确做法（引以为戒）

**任何 Godot API 操作之前，必须查官方文档确认：**

1. 属性是否真实存在
2. 属性类型是否正确（Vector2/Vector3、float/int）
3. 常量枚举值是否正确
4. 优先用编辑器节点 + @onready，而不是运行时 new()
