## 网格单元格数据结构
## 存储单元格的坐标、类型和元数据信息
##
## 使用示例：
## ```gdscript
## var cell = GridCell.new(Vector2i(3, 5), 1)
## cell.set_meta_value("revealed", true)
## cell.set_meta_value("score", 10)
## print(cell.get_meta_value("score"))  # 输出: 10
## ```
class_name GridCell
extends RefCounted

## 单元格在网格中的坐标
var position: Vector2i = Vector2i.ZERO

## 单元格类型（由具体游戏定义含义）
var cell_type: int = 0

## 单元格是否已被揭示
var revealed: bool = false

## 单元格是否被覆盖（阻挡交互）
var covered: bool = true

## 元数据字典，存储自定义键值对
var _metadata: Dictionary = {}

## 初始化单元格
## @param pos 单元格坐标
## @param type 单元格类型
func _init(pos: Vector2i = Vector2i.ZERO, type: int = 0) -> void:
	position = pos
	cell_type = type

## 获取元数据值
## @param key 键名
## @param default 默认值（键不存在时返回）
## @return 元数据值
func get_meta_value(key: String, default: Variant = null) -> Variant:
	return _metadata.get(key, default)

## 设置元数据值
## @param key 键名
## @param value 值
func set_meta_value(key: String, value: Variant) -> void:
	_metadata[key] = value

## 检查是否存在指定的元数据键
## @param key 键名
## @return 是否存在
func has_meta_value(key: String) -> bool:
	return _metadata.has(key)

## 移除指定的元数据键
## @param key 键名
func remove_meta_value(key: String) -> void:
	_metadata.erase(key)

## 清空所有元数据
func clear_metadata() -> void:
	_metadata.clear()

## 重置单元格状态
func reset() -> void:
	cell_type = 0
	revealed = false
	covered = true
	_metadata.clear()

## 转换为字符串表示（用于调试）
func _to_string() -> String:
	return "GridCell(%s, type=%d, revealed=%s)" % [position, cell_type, revealed]
