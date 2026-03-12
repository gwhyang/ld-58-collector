## 升级定义资源类
## 描述一个升级项的所有信息，包括名称、描述、费用和效果
##
## 每个升级项的每个等级对应一个 UpgradeDefinition 实例。
## 通过 UpgradeManager.register_upgrade() 注册后使用。
##
## 使用示例：
## [codeblock]
## var def = UpgradeDefinition.new()
## def.upgrade_id = "axe"
## def.upgrade_name = "镐子升级"
## def.description = "挖掘石头消耗行动点 -1"
## def.costs = {0: 5, 1: 3}
## def.max_level = 3
## [/codeblock]
class_name UpgradeDefinition
extends Resource

## 升级项的唯一标识符
@export var upgrade_id: String = ""

## 升级项的显示名称
@export var upgrade_name: String = ""

## 升级效果的文字描述
@export var description: String = ""

## 升级项的图标（可选）
@export var icon: Texture2D = null

## 升级所需的资源费用
## 键为资源类型ID（int），值为所需数量（int）
@export var costs: Dictionary = {}

## 该升级项的最大等级
@export var max_level: int = 1

## 升级效果脚本的路径（可选）
## 指向一个实现了 apply(target) 方法的 GDScript
@export var effect_script: String = ""

## 验证升级定义是否合法
## 检查必要字段是否已填写、费用是否有效
## @return 验证通过返回true，否则返回false
func validate() -> bool:
	if upgrade_id.is_empty():
		push_warning("UpgradeDefinition: upgrade_id 不能为空")
		return false
	if costs.is_empty():
		push_warning("UpgradeDefinition: '%s' 的费用不能为空" % upgrade_id)
		return false
	if max_level < 1:
		push_warning("UpgradeDefinition: '%s' 的 max_level 必须大于等于1" % upgrade_id)
		return false
	# 检查费用值是否为正整数
	for type in costs:
		if costs[type] <= 0:
			push_warning("UpgradeDefinition: '%s' 的费用项 %s 必须大于0" % [upgrade_id, str(type)])
			return false
	return true
