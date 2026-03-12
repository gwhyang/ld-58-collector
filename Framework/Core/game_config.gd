## 游戏配置基类
## 提供类型安全的配置管理框架
##
## 子类通过 @export 暴露配置项，支持编辑器内调整。
## 提供配置验证和常用工具方法。
##
## 使用示例：
## [codeblock]
## class_name MyGameConfig
## extends GameConfig
##
## @export var grid_size: Vector2i = Vector2i(12, 10)
## @export var max_hp: int = 100
## [/codeblock]
class_name GameConfig
extends Resource

## 网格尺寸（子类可覆盖）
@export var grid_size: Vector2i = Vector2i(10, 10)

## 根据网格尺寸计算网格区域矩形
## @return 从原点开始的网格矩形
func get_grid_rect() -> Rect2i:
	return Rect2i(Vector2i.ZERO, grid_size)

## 验证配置是否合法
## 子类应覆盖此方法添加自定义验证逻辑
## @return 配置是否有效
func validate() -> bool:
	if grid_size.x <= 0 or grid_size.y <= 0:
		push_error("GameConfig: grid_size 必须大于0")
		return false
	return true
