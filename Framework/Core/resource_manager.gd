## 资源管理器基类
## 管理玩家拥有的各种资源（矿物、货币等）
##
## 提供通用的资源增减、批量消耗和查询功能。
## 通过信号通知外部系统资源变化。
##
## 使用示例：
## [codeblock]
## var manager = ResourceManager.new()
## manager.initialize_resources({0: 0, 1: 0, 2: 0})
## manager.add_resource(0, 100)
## if manager.consume_resource(0, 50):
##     print("消耗成功")
## [/codeblock]
class_name ResourceManager
extends Node

## 资源发生变化时发出
## @param resource_type 资源类型ID
## @param old_value 变化前的数量
## @param new_value 变化后的数量
signal resource_changed(resource_type: int, old_value: int, new_value: int)

## 所有资源被重置时发出
signal resources_reset()

## 资源存储字典，键为资源类型ID，值为持有数量
var _resources: Dictionary = {}

## 初始化资源列表
## @param resource_types 资源类型到初始值的映射字典
func initialize_resources(resource_types: Dictionary) -> void:
	_resources.clear()
	for type in resource_types:
		_resources[type] = resource_types[type]

## 添加指定数量的资源
## @param resource_type 资源类型ID
## @param amount 添加数量（必须大于0）
func add_resource(resource_type: int, amount: int) -> void:
	if amount <= 0:
		return
	var old_value: int = _resources.get(resource_type, 0)
	var new_value: int = old_value + amount
	_resources[resource_type] = new_value
	resource_changed.emit(resource_type, old_value, new_value)

## 消耗指定数量的资源
## @param resource_type 资源类型ID
## @param amount 消耗数量
## @return 是否消耗成功（资源不足时返回false）
func consume_resource(resource_type: int, amount: int) -> bool:
	var current: int = _resources.get(resource_type, 0)
	if current < amount:
		return false
	var new_value: int = current - amount
	_resources[resource_type] = new_value
	resource_changed.emit(resource_type, current, new_value)
	return true

## 批量消耗多种资源
## 先检查所有资源是否充足，只有全部满足时才执行扣除
## @param costs 资源类型到消耗数量的映射字典
## @return 是否全部消耗成功
func consume_resources(costs: Dictionary) -> bool:
	# 先检查所有资源是否充足
	for type in costs:
		var current: int = _resources.get(type, 0)
		if current < costs[type]:
			return false
	# 全部满足，执行扣除
	for type in costs:
		var old_value: int = _resources[type]
		_resources[type] -= costs[type]
		resource_changed.emit(type, old_value, _resources[type])
	return true

## 获取指定资源的当前数量
## @param resource_type 资源类型ID
## @return 资源数量，不存在时返回0
func get_resource(resource_type: int) -> int:
	return _resources.get(resource_type, 0)

## 重置所有资源为0
func reset_resources() -> void:
	for type in _resources:
		_resources[type] = 0
	resources_reset.emit()
