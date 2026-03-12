## 网格模式类
## 定义可重用的网格偏移模式（3x3、5x5、十字形等）
##
## 使用示例：
## ```gdscript
## var cross = GridPattern.create_cross()
## var neighbors = cross.get_neighbors(Vector2i(5, 5))
## for neighbor in neighbors:
##     print(neighbor)
## ```
class_name GridPattern
extends RefCounted

## 模式名称
var pattern_name: String = ""

## 偏移量数组，定义模式中的相对坐标
var offsets: Array[Vector2i] = []

## 是否包含中心点
var include_center: bool = false

## 创建自定义网格模式
## @param name 模式名称
## @param offset_array 偏移量数组
## @param with_center 是否包含中心点
func _init(name: String = "", offset_array: Array[Vector2i] = [], with_center: bool = false) -> void:
	pattern_name = name
	offsets = offset_array
	include_center = with_center

## 获取指定中心点的所有邻居坐标
## @param center 中心坐标
## @return 邻居坐标数组
func get_neighbors(center: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset in offsets:
		result.append(center + offset)
	return result

## 获取在指定边界范围内的邻居坐标
## @param center 中心坐标
## @param bounds 边界矩形
## @return 在边界内的邻居坐标数组
func get_neighbors_in_bounds(center: Vector2i, bounds: Rect2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset in offsets:
		var pos: Vector2i = center + offset
		if bounds.has_point(pos):
			result.append(pos)
	return result

## 获取偏移量数量
func get_size() -> int:
	return offsets.size()

# ========== 静态工厂方法 ==========

## 创建十字形模式（上下左右四个方向）
static func create_cross() -> GridPattern:
	var pattern = GridPattern.new("cross", [
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(0, -1), Vector2i(0, 1)
	], false)
	return pattern

## 创建3x3模式（包含中心点的9个格子）
static func create_3x3() -> GridPattern:
	var pattern = GridPattern.new("3x3", [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0),  Vector2i(0, 0),  Vector2i(1, 0),
		Vector2i(-1, 1),  Vector2i(0, 1),  Vector2i(1, 1)
	], true)
	return pattern

## 创建5x5模式（包含中心点的25个格子）
static func create_5x5() -> GridPattern:
	var offsets_array: Array[Vector2i] = []
	for x in range(-2, 3):
		for y in range(-2, 3):
			offsets_array.append(Vector2i(x, y))
	var pattern = GridPattern.new("5x5", offsets_array, true)
	return pattern

## 创建菱形模式（曼哈顿距离内的格子）
## @param radius 菱形半径
static func create_diamond(radius: int) -> GridPattern:
	var offsets_array: Array[Vector2i] = []
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if absi(x) + absi(y) <= radius:
				offsets_array.append(Vector2i(x, y))
	var pattern = GridPattern.new("diamond_%d" % radius, offsets_array, true)
	return pattern
