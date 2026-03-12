## 程序生成基类
## 提供通用的程序化生成流程框架，子类需要实现具体的生成算法
##
## 使用示例：
## ```gdscript
## class_name MyGenerator
## extends ProceduralGeneratorBase
##
## func generate() -> Dictionary:
##     var result := {}
##     # 自定义生成逻辑...
##     generation_completed.emit(result)
##     return result
## ```
class_name ProceduralGeneratorBase
extends Node

## 生成完成时发出，携带生成结果
signal generation_completed(result: Dictionary)

## 生成失败时发出，携带错误信息
signal generation_failed(error_message: String)

## 网格尺寸（宽 x 高）
var grid_size: Vector2i = Vector2i.ZERO

## 预留单元格，生成时不会覆盖这些位置
## 格式：{ Vector2i: 值 }
var preserved_cells: Dictionary = {}

## 生成网格数据（抽象方法，子类必须实现）
## @return 生成的网格数据字典 { Vector2i: 值 }
func generate() -> Dictionary:
	push_error("ProceduralGeneratorBase.generate() 是抽象方法，子类必须重写")
	generation_failed.emit("未实现的抽象方法 generate()")
	return {}

## 验证生成参数是否合法
## @return 参数是否有效
func validate_parameters() -> bool:
	if grid_size.x <= 0 or grid_size.y <= 0:
		push_error("网格尺寸无效: %s" % str(grid_size))
		return false
	return true

## 检查坐标是否在网格边界内
## @param cell 要检查的坐标
## @return 是否在边界内
func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < grid_size.x and cell.y >= 0 and cell.y < grid_size.y

## 检查坐标是否为预留单元格
## @param cell 要检查的坐标
## @return 是否为预留单元格
func is_preserved(cell: Vector2i) -> bool:
	return preserved_cells.has(cell)
