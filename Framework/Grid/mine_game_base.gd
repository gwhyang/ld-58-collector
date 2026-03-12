## 挖矿游戏基类
## 继承自 GridGameBase，提供挖矿游戏通用功能
## 包含行动点系统、矿物收集、关卡管理、挖掘状态机等
##
## 使用示例：
## ```gdscript
## extends MineGameBase
##
## func start_new_level(start_cell: Vector2i) -> void:
##     # 生成洞穴并初始化关卡
##     pass
##
## func process_dig_action(cell: Vector2i) -> void:
##     # 处理具体的挖掘逻辑
##     pass
## ```
class_name MineGameBase
extends GridGameBase

# ========== 枚举定义 ==========

## 挖矿状态枚举
enum MineState {
	WAITING_START,  ## 等待玩家点击开始位置
	PROCESSING,     ## 挖掘进行中
	FAIL            ## 挖掘失败
}

# ========== 信号定义 ==========

## 行动点变化时发出
## @param current 当前行动点
## @param maximum 最大行动点
signal action_points_changed(current: int, maximum: int)

## 进入矿场时发出
signal game_enter()

## 离开矿场时发出
signal game_exit()

# ========== 状态变量 ==========

## 当前挖矿状态
var mine_state: MineState = MineState.WAITING_START

## 当前行动点（自动钳制到 [0, max_action_points] 并发出变化信号）
var action_points: int = 10:
	set(value):
		var old := action_points
		action_points = clampi(value, 0, max_action_points)
		if action_points != old:
			action_points_changed.emit(action_points, max_action_points)

## 最大行动点
var max_action_points: int = 10

## 当前关卡深度
var current_level: int = 0

## 本次挖掘收集的矿物 {矿物类型: 数量}
var gained_minerals: Dictionary = {}

# ========== 核心方法 ==========

## 尝试挖掘
## 根据当前挖矿状态分发到不同的处理方法：
## - WAITING_START: 调用 start_new_level() 开始新关卡
## - PROCESSING: 调用 process_dig_action() 处理挖掘
## - FAIL: 调用 restart_game() 重启游戏
## @param cell 目标单元格坐标
func try_dig(cell: Vector2i) -> void:
	match mine_state:
		MineState.WAITING_START:
			start_new_level(cell)
		MineState.PROCESSING:
			process_dig_action(cell)
		MineState.FAIL:
			restart_game()

## 开始新关卡（子类必须实现）
## 负责生成洞穴地形、放置特殊方块、初始化关卡数据
## @param start_cell 玩家选择的起始单元格坐标
func start_new_level(start_cell: Vector2i) -> void:
	pass

## 处理挖掘动作（子类必须实现）
## 负责判断挖掘目标、消耗行动点、收集矿物等具体逻辑
## @param cell 玩家挖掘的单元格坐标
func process_dig_action(cell: Vector2i) -> void:
	pass

## 消耗行动点
## 如果行动点不足则触发游戏失败
## @param amount 消耗数量
## @return 是否成功消耗（行动点充足返回 true）
func consume_action_points(amount: int) -> bool:
	if action_points < amount:
		game_fail()
		return false
	action_points -= amount
	return true

## 游戏失败处理
## 将挖矿状态设为 FAIL，游戏状态设为 GAME_OVER，清空收集的矿物
## 子类可重写以添加失败音效、粒子效果等
func game_fail() -> void:
	mine_state = MineState.FAIL
	current_state = GameState.GAME_OVER
	gained_minerals.clear()

## 重启游戏
## 重置所有状态到初始值，准备开始新一轮游戏
## 子类可重写以添加额外的重置逻辑
func restart_game() -> void:
	mine_state = MineState.WAITING_START
	current_state = GameState.IDLE
	action_points = max_action_points
	current_level = 0
	gained_minerals.clear()

## 离开矿场
## 子类应重写此方法以实现具体的资源保存逻辑（如将矿物存入玩家背包）
## 重写时建议在保存完成后调用 super.exit_mine() 以发出 game_exit 信号
func exit_mine() -> void:
	game_exit.emit()
