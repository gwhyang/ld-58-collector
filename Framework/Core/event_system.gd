## 通用事件系统
## 支持运行时动态注册事件类型，替代硬编码的信号方案
##
## 允许在运行时注册新事件、连接监听器、触发事件。
## 比 Godot 内置信号更灵活，适用于跨模块的松耦合通信。
##
## 使用示例：
## [codeblock]
## var events = EventSystem.new()
## events.register_event("player_died")
## events.connect_event("player_died", func(data): print("玩家死亡"))
## events.emit_event("player_died", {"cause": "trap"})
## [/codeblock]
class_name EventSystem
extends Node

## 内部事件信号包装类
## 每个注册的事件对应一个 EventSignal 实例
class EventSignal:
	## 事件触发时发出，携带事件数据
	signal triggered(data: Dictionary)

	## 触发该事件
	func emit_data(data: Dictionary) -> void:
		triggered.emit(data)

	## 连接监听器
	func connect_listener(callable: Callable) -> void:
		triggered.connect(callable)

	## 断开监听器
	func disconnect_listener(callable: Callable) -> void:
		if triggered.is_connected(callable):
			triggered.disconnect(callable)

## 已注册事件的字典，键为事件名称，值为 EventSignal 实例
var _events: Dictionary = {}

## 注册一个新事件类型
## 如果事件已存在则跳过
## @param event_name 事件名称
func register_event(event_name: String) -> void:
	if _events.has(event_name):
		return
	_events[event_name] = EventSignal.new()

## 连接事件监听器
## 如果事件未注册，会自动注册
## @param event_name 事件名称
## @param callable 回调函数，接收一个 Dictionary 参数
func connect_event(event_name: String, callable: Callable) -> void:
	if not _events.has(event_name):
		register_event(event_name)
	(_events[event_name] as EventSignal).connect_listener(callable)

## 断开事件监听器
## @param event_name 事件名称
## @param callable 要断开的回调函数
func disconnect_event(event_name: String, callable: Callable) -> void:
	if not _events.has(event_name):
		return
	(_events[event_name] as EventSignal).disconnect_listener(callable)

## 触发事件，通知所有监听器
## @param event_name 事件名称
## @param data 事件数据字典（默认为空字典）
func emit_event(event_name: String, data: Dictionary = {}) -> void:
	if not _events.has(event_name):
		push_warning("EventSystem: 尝试触发未注册的事件 '%s'" % event_name)
		return
	(_events[event_name] as EventSignal).emit_data(data)

## 检查事件是否已注册
## @param event_name 事件名称
## @return 事件是否存在
func has_event(event_name: String) -> bool:
	return _events.has(event_name)
