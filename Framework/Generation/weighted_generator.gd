## 基于权重的程序生成器
## 继承自 ProceduralGeneratorBase，使用权重分布来决定每个单元格的类型
##
## 使用示例：
## ```gdscript
## var generator = WeightedGenerator.new()
## generator.grid_size = Vector2i(12, 10)
## generator.preserved_cells = { Vector2i(0, 0): some_type }
## generator.weight_pairs = { type_a: 0.5, type_b: 0.3, type_c: 0.2 }
## var result = generator.generate()
## ```
class_name WeightedGenerator
extends ProceduralGeneratorBase

## 类型权重对，格式：{ 类型: 权重值 }
## 权重值不需要归一化，生成时会自动归一化
var weight_pairs: Dictionary = {}

## 根据权重分布生成网格
## @return 生成的网格数据 { Vector2i: 类型 }
func generate() -> Dictionary:
	if not validate_parameters():
		generation_failed.emit("参数验证失败")
		return {}

	if weight_pairs.is_empty():
		push_error("权重对为空，无法生成")
		generation_failed.emit("权重对为空")
		return {}

	var result := {}
	var weights := _normalize_weights(weight_pairs)

	# 先填入预留单元格
	for cell in preserved_cells:
		if not is_in_bounds(cell):
			push_error("预留单元格 %s 超出边界" % str(cell))
			continue
		result[cell] = preserved_cells[cell]

	# 遍历所有单元格，根据权重随机分配类型
	for x in grid_size.x:
		for y in grid_size.y:
			var cell := Vector2i(x, y)
			if is_preserved(cell):
				continue
			result[cell] = _select_type_by_weight(weights)

	generation_completed.emit(result)
	return result

## 归一化权重，使所有权重之和为 1.0
## @param weights 原始权重字典
## @return 归一化后的权重字典
func _normalize_weights(weights: Dictionary) -> Dictionary:
	var normalized := weights.duplicate()
	var total_weight: float = 0.0

	for key in weights:
		total_weight += float(weights[key])

	if total_weight <= 0.0:
		push_error("权重总和为零或负数，无法归一化")
		return normalized

	for key in weights:
		normalized[key] = float(weights[key]) / total_weight

	return normalized

## 根据归一化后的权重随机选择一个类型
## @param weights 归一化后的权重字典（值之和为 1.0）
## @return 随机选中的类型
func _select_type_by_weight(weights: Dictionary):
	var rand_value := randf()
	for type in weights:
		rand_value -= weights[type]
		if rand_value <= 0.0:
			return type
	# 浮点精度兜底：返回最后一个类型
	return weights.keys().back()
