## 矿洞收集者 - 游戏配置
## 继承自 GameConfig，定义游戏专用的配置参数
class_name MineGameConfig
extends GameConfig

# --- 洞穴配置 ---
@export_group("洞穴配置")

## 洞穴网格尺寸（列 x 行）
@export var cave_size: Vector2i = Vector2i(12, 10)

## 活板门之间的最小距离
@export var min_trapdoor_distance: int = 5

# --- 行动点配置 ---
@export_group("行动点配置")

## 基础最大行动点
@export var base_max_ap: int = 7

## 进入下一层时恢复的行动点
@export var layer_heal_amount: int = 2

## 红色矿石恢复的行动点
@export var red_mineral_heal: int = 5

# --- 动画配置 ---
@export_group("动画配置")

## 矿石移动动画持续时间（秒）
@export var mineral_move_duration: float = 0.5


## 获取洞穴区域矩形
func get_cave_rect() -> Rect2i:
	return Rect2i(Vector2i.ZERO, cave_size)


## 验证配置是否合法
func validate() -> bool:
	if not super.validate():
		return false

	if cave_size.x <= 0 or cave_size.y <= 0:
		push_error("MineGameConfig: cave_size 必须大于0")
		return false

	if min_trapdoor_distance <= 0:
		push_error("MineGameConfig: min_trapdoor_distance 必须大于0")
		return false

	if base_max_ap <= 0:
		push_error("MineGameConfig: base_max_ap 必须大于0")
		return false

	if layer_heal_amount < 0:
		push_error("MineGameConfig: layer_heal_amount 不能为负数")
		return false

	if mineral_move_duration <= 0.0:
		push_error("MineGameConfig: mineral_move_duration 必须大于0")
		return false

	return true
