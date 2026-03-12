## 网格游戏基类
## 提供通用的网格交互、图层管理和状态机功能
## 子类应继承此类并实现具体的游戏逻辑
##
## 使用示例：
## ```gdscript
## extends GridGameBase
## class_name MineGame
##
## func on_cell_clicked(cell: Vector2i) -> void:
##     # 处理点击逻辑
##     pass
##
## func on_enter_playing() -> void:
##     # 进入游戏状态时的初始化
##     pass
## ```
class_name GridGameBase
extends Node

# ========== 枚举定义 ==========

## 游戏状态枚举
enum GameState {
	IDLE,       ## 空闲状态（等待开始）
	PLAYING,    ## 游戏进行中
	PAUSED,     ## 暂停状态
	GAME_OVER   ## 游戏结束
}

# ========== 信号定义 ==========

## 游戏状态变化时发出
## @param old_state 旧状态
## @param new_state 新状态
signal state_changed(old_state: GameState, new_state: GameState)

## 单元格被点击时发出
## @param cell 被点击的单元格坐标
signal cell_clicked(cell: Vector2i)

## 单元格被揭示时发出
## @param cell 被揭示的单元格坐标
## @param cell_type 单元格类型
signal cell_revealed(cell: Vector2i, cell_type: int)

## 游戏开始时发出
signal game_started

## 游戏结束时发出
## @param is_victory 是否胜利
signal game_ended(is_victory: bool)

# ========== 导出变量 ==========

## 是否启用交互
@export var interactive: bool = true

# ========== 图层引用 ==========

## 主网格图层（存储实际的单元格内容）
var grid_layer: TileMapLayer

## 覆盖图层（阻挡玩家交互的覆盖物）
var cover_layer: TileMapLayer

## 提示图层（显示周围信息的提示）
var hint_layer: TileMapLayer

# ========== 状态变量 ==========

## 当前游戏状态
var current_state: GameState = GameState.IDLE:
	set(value):
		if value == current_state:
			return
		var old_state = current_state
		# 退出旧状态回调
		_call_state_exit(old_state)
		current_state = value
		# 进入新状态回调
		_call_state_enter(value)
		state_changed.emit(old_state, value)

## 网格模式字典，存储预定义的网格模式
## 键为模式名称（String），值为 GridPattern 实例
var patterns: Dictionary = {}

## 网格边界区域
var grid_bounds: Rect2i = Rect2i()

# ========== 生命周期方法 ==========

func _ready() -> void:
	_init_patterns()
	_setup_layers()

## 初始化预定义网格模式
## 子类可重写此方法添加自定义模式
func _init_patterns() -> void:
	patterns["cross"] = GridPattern.create_cross()
	patterns["3x3"] = GridPattern.create_3x3()
	patterns["5x5"] = GridPattern.create_5x5()

## 设置图层引用
## 子类应重写此方法以绑定具体的 TileMapLayer 节点
func _setup_layers() -> void:
	pass

# ========== 状态机 ==========

## 根据状态调用对应的进入回调
func _call_state_enter(state: GameState) -> void:
	match state:
		GameState.IDLE:
			on_enter_idle()
		GameState.PLAYING:
			on_enter_playing()
		GameState.PAUSED:
			on_enter_paused()
		GameState.GAME_OVER:
			on_enter_game_over()

## 根据状态调用对应的退出回调
func _call_state_exit(state: GameState) -> void:
	match state:
		GameState.IDLE:
			on_exit_idle()
		GameState.PLAYING:
			on_exit_playing()
		GameState.PAUSED:
			on_exit_paused()
		GameState.GAME_OVER:
			on_exit_game_over()

## 进入空闲状态时的回调（子类重写）
func on_enter_idle() -> void:
	pass

## 退出空闲状态时的回调（子类重写）
func on_exit_idle() -> void:
	pass

## 进入游戏状态时的回调（子类重写）
func on_enter_playing() -> void:
	game_started.emit()

## 退出游戏状态时的回调（子类重写）
func on_exit_playing() -> void:
	pass

## 进入暂停状态时的回调（子类重写）
func on_enter_paused() -> void:
	pass

## 退出暂停状态时的回调（子类重写）
func on_exit_paused() -> void:
	pass

## 进入游戏结束状态时的回调（子类重写）
func on_enter_game_over() -> void:
	game_ended.emit(false)

## 退出游戏结束状态时的回调（子类重写）
func on_exit_game_over() -> void:
	pass

# ========== 输入处理 ==========

## 处理鼠标点击事件
## 将屏幕坐标转换为网格坐标并触发点击逻辑
## @param mouse_position 鼠标全局坐标
func handle_mouse_click(mouse_position: Vector2) -> void:
	if not interactive:
		return
	if not grid_layer:
		return

	var cell := grid_layer.local_to_map(grid_layer.to_local(mouse_position))

	# 检查是否在网格边界内
	if grid_bounds.size != Vector2i.ZERO and not grid_bounds.has_point(cell):
		return

	cell_clicked.emit(cell)
	on_cell_clicked(cell)

## 单元格被点击时的回调（子类必须重写）
## @param cell 被点击的单元格坐标
func on_cell_clicked(cell: Vector2i) -> void:
	pass

# ========== 网格操作 ==========

## 揭示指定单元格
## 移除覆盖物并发出揭示信号
## @param cell 要揭示的单元格坐标
func reveal_cell(cell: Vector2i) -> void:
	if not grid_layer:
		return

	# 获取单元格类型
	var cell_type: int = get_cell_type(cell)

	# 移除隐藏层覆盖
	if hint_layer:
		hint_layer.erase_cell(cell)

	cell_revealed.emit(cell, cell_type)

## 获取指定单元格的类型
## 子类应重写此方法以适配自己的类型系统
## @param cell 单元格坐标
## @return 单元格类型ID
func get_cell_type(cell: Vector2i) -> int:
	if not grid_layer:
		return -1
	var data: TileData = grid_layer.get_cell_tile_data(cell)
	if not data:
		return -1
	return 0

## 检查指定单元格是否被覆盖
## @param cell 单元格坐标
## @return 是否被覆盖
func is_cell_covered(cell: Vector2i) -> bool:
	if not cover_layer:
		return false
	return cell in cover_layer.get_used_cells()

## 检查指定单元格是否已被揭示
## @param cell 单元格坐标
## @return 是否已揭示
func is_cell_revealed(cell: Vector2i) -> bool:
	if not hint_layer:
		return true
	return not (cell in hint_layer.get_used_cells())

## 使用指定模式更新邻居单元格
## @param cell 中心单元格坐标
## @param pattern_name 模式名称（如 "3x3"、"cross" 等）
func update_neighbors(cell: Vector2i, pattern_name: String) -> void:
	var pattern: GridPattern = patterns.get(pattern_name)
	if not pattern:
		push_warning("GridGameBase: 未找到模式 '%s'" % pattern_name)
		return

	var neighbors: Array[Vector2i] = pattern.get_neighbors(cell)
	for neighbor in neighbors:
		on_neighbor_update(cell, neighbor)

## 邻居单元格更新回调（子类重写）
## @param source 触发更新的源单元格
## @param neighbor 需要更新的邻居单元格
func on_neighbor_update(source: Vector2i, neighbor: Vector2i) -> void:
	pass

# ========== 工具方法 ==========

## 获取指定模式的邻居坐标
## @param cell 中心坐标
## @param pattern_name 模式名称
## @return 邻居坐标数组
func get_pattern_neighbors(cell: Vector2i, pattern_name: String) -> Array[Vector2i]:
	var pattern: GridPattern = patterns.get(pattern_name)
	if not pattern:
		push_warning("GridGameBase: 未找到模式 '%s'" % pattern_name)
		return []
	return pattern.get_neighbors(cell)

## 获取在边界内的模式邻居坐标
## @param cell 中心坐标
## @param pattern_name 模式名称
## @return 在边界内的邻居坐标数组
func get_bounded_neighbors(cell: Vector2i, pattern_name: String) -> Array[Vector2i]:
	var pattern: GridPattern = patterns.get(pattern_name)
	if not pattern:
		push_warning("GridGameBase: 未找到模式 '%s'" % pattern_name)
		return []
	if grid_bounds.size == Vector2i.ZERO:
		return pattern.get_neighbors(cell)
	return pattern.get_neighbors_in_bounds(cell, grid_bounds)

## 重置游戏到初始状态
func reset_game() -> void:
	current_state = GameState.IDLE

## 开始游戏
func start_game() -> void:
	current_state = GameState.PLAYING

## 暂停游戏
func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED

## 恢复游戏
func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING

## 结束游戏
## @param victory 是否胜利结束
func end_game(victory: bool = false) -> void:
	current_state = GameState.GAME_OVER
