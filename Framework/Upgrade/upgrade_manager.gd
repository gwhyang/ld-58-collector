## 升级管理器
## 管理所有升级项的注册、购买和效果应用
##
## 集中处理升级逻辑，包括资源检查、费用扣除和等级管理。
## 需要引用 ResourceManager 来执行资源扣除操作。
##
## 使用示例：
## [codeblock]
## var manager = UpgradeManager.new(resource_manager)
## var levels: Array[UpgradeDefinition] = [level1_def, level2_def]
## manager.register_upgrade("axe", levels)
## if manager.try_purchase_upgrade("axe"):
##     print("升级成功")
## [/codeblock]
class_name UpgradeManager
extends Node

## 升级购买成功时发出
## @param upgrade_id 升级项ID
## @param new_level 升级后的等级
signal upgrade_purchased(upgrade_id: String, new_level: int)

## 升级购买失败时发出
## @param upgrade_id 升级项ID
## @param reason 失败原因
signal upgrade_failed(upgrade_id: String, reason: String)

## 资源管理器引用，用于检查和扣除资源
var _resource_manager: ResourceManager = null

## 已注册的升级项定义
## 键为升级项ID，值为该升级项各等级的 UpgradeDefinition 数组
var _upgrades: Dictionary = {}

## 各升级项的当前等级
## 键为升级项ID，值为当前等级（从0开始，0表示未升级）
var _current_levels: Dictionary = {}

## 构造函数
## @param resource_manager 资源管理器实例
func _init(resource_manager: ResourceManager = null) -> void:
	_resource_manager = resource_manager

## 设置资源管理器引用
## @param resource_manager 资源管理器实例
func set_resource_manager(resource_manager: ResourceManager) -> void:
	_resource_manager = resource_manager

## 注册一个升级项及其各等级定义
## @param upgrade_id 升级项的唯一标识符
## @param levels 该升级项各等级的 UpgradeDefinition 数组
func register_upgrade(upgrade_id: String, levels: Array) -> void:
	if upgrade_id.is_empty():
		push_warning("UpgradeManager: 升级项ID不能为空")
		return
	if levels.is_empty():
		push_warning("UpgradeManager: 升级项 '%s' 的等级定义不能为空" % upgrade_id)
		return
	# 验证每个等级定义
	for i in range(levels.size()):
		var def: UpgradeDefinition = levels[i]
		if not def.validate():
			push_warning("UpgradeManager: 升级项 '%s' 的第 %d 级定义验证失败" % [upgrade_id, i + 1])
			return
	_upgrades[upgrade_id] = levels
	_current_levels[upgrade_id] = 0

## 尝试购买指定升级项的下一级
## 自动检查资源是否充足，充足则扣除并升级
## @param upgrade_id 升级项ID
## @return 是否购买成功
func try_purchase_upgrade(upgrade_id: String) -> bool:
	# 检查升级项是否已注册
	if not _upgrades.has(upgrade_id):
		upgrade_failed.emit(upgrade_id, "升级项 '%s' 未注册" % upgrade_id)
		return false

	# 检查是否已达到最大等级
	var current_level: int = _current_levels[upgrade_id]
	var levels: Array = _upgrades[upgrade_id]
	if current_level >= levels.size():
		upgrade_failed.emit(upgrade_id, "升级项 '%s' 已达到最大等级" % upgrade_id)
		return false

	# 检查资源管理器是否可用
	if _resource_manager == null:
		upgrade_failed.emit(upgrade_id, "资源管理器未设置")
		return false

	# 获取下一级的定义
	var next_def: UpgradeDefinition = levels[current_level]

	# 尝试消耗资源
	if not _resource_manager.consume_resources(next_def.costs):
		upgrade_failed.emit(upgrade_id, "资源不足，无法购买 '%s'" % upgrade_id)
		return false

	# 资源扣除成功，提升等级
	_current_levels[upgrade_id] = current_level + 1

	# 应用升级效果
	apply_upgrade_effect(upgrade_id, next_def)

	# 发出升级成功信号
	upgrade_purchased.emit(upgrade_id, _current_levels[upgrade_id])
	return true

## 应用升级效果
## 如果升级定义中指定了效果脚本，则加载并执行
## @param upgrade_id 升级项ID
## @param definition 升级定义
func apply_upgrade_effect(upgrade_id: String, definition: UpgradeDefinition) -> void:
	if definition.effect_script.is_empty():
		return
	# 加载并执行效果脚本
	if ResourceLoader.exists(definition.effect_script):
		var script: GDScript = load(definition.effect_script) as GDScript
		if script and script.has_method("apply"):
			script.apply(self)
		else:
			push_warning("UpgradeManager: 效果脚本 '%s' 缺少 apply 方法" % definition.effect_script)
	else:
		push_warning("UpgradeManager: 效果脚本 '%s' 不存在" % definition.effect_script)

## 获取指定升级项的当前等级
## @param upgrade_id 升级项ID
## @return 当前等级，未注册时返回0
func get_upgrade_level(upgrade_id: String) -> int:
	return _current_levels.get(upgrade_id, 0)

## 获取指定升级项的下一级定义
## @param upgrade_id 升级项ID
## @return 下一级的 UpgradeDefinition，如果已满级或未注册则返回null
func get_next_upgrade(upgrade_id: String) -> UpgradeDefinition:
	if not _upgrades.has(upgrade_id):
		return null
	var current_level: int = _current_levels[upgrade_id]
	var levels: Array = _upgrades[upgrade_id]
	if current_level >= levels.size():
		return null
	return levels[current_level]

## 检查指定升级项是否已达到最大等级
## @param upgrade_id 升级项ID
## @return 是否已满级
func is_max_level(upgrade_id: String) -> bool:
	if not _upgrades.has(upgrade_id):
		return false
	return _current_levels[upgrade_id] >= _upgrades[upgrade_id].size()

## 重置指定升级项的等级为0
## @param upgrade_id 升级项ID
func reset_upgrade(upgrade_id: String) -> void:
	if _current_levels.has(upgrade_id):
		_current_levels[upgrade_id] = 0

## 重置所有升级项的等级为0
func reset_all_upgrades() -> void:
	for upgrade_id in _current_levels:
		_current_levels[upgrade_id] = 0
