## 游戏状态管理基类
## 提供游戏运行时状态的基础管理结构
##
## 子类继承此基类来实现游戏特定的状态管理。
## 提供状态变化通知和重置功能。
##
## 使用示例：
## [codeblock]
## class_name MineGameState
## extends GameStateBase
##
## var axe_level: int = 0
## var max_ap: int = 7
## [/codeblock]
class_name GameStateBase
extends Node

## 状态被重置时发出
signal state_reset()

## 状态发生变化时发出
## @param property_name 变化的属性名
## @param old_value 旧值
## @param new_value 新值
signal state_changed(property_name: String, old_value: Variant, new_value: Variant)

## 重置状态到初始值
## 子类应覆盖此方法实现具体的重置逻辑
func reset() -> void:
	state_reset.emit()

## 通知状态变化的辅助方法
## 子类在修改状态时调用此方法发出信号
## @param property_name 属性名称
## @param old_value 变化前的值
## @param new_value 变化后的值
func notify_state_changed(property_name: String, old_value: Variant, new_value: Variant) -> void:
	state_changed.emit(property_name, old_value, new_value)
