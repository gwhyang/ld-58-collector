extends Node
## 全局游戏管理器 - 向后兼容层
##
## 作为轻量级协调器，将旧的全局状态访问方式代理到新的模块化架构。
## 所有旧代码通过 Game.xxx 的访问方式保持不变。
##
## 新架构模块：
## - MineGameConstants: 常量定义（矿物类型、名称、坐标等）
## - MineGameConfig:    游戏配置（洞穴尺寸、动画时间等）
## - MineGameState:     运行时状态（升级等级、资源、可变数据）
## - EventSystem:       通用事件系统

# ── 新模块实例 ────────────────────────────────────────────────────
## 游戏配置
var config: MineGameConfig
## 运行时状态
var state: MineGameState
## 事件系统
var events: EventSystem

# ── 向后兼容：矿物类型枚举 ───────────────────────────────────────
## @deprecated 使用 MineGameConstants.MineralType 代替
## 保留旧的小写枚举值，确保所有现有代码（Game.MineralType.none 等）继续工作
enum MineralType {none, white, black, gold, blue, brown, red, trapdoor, lifter, cover, hide}

# ── 向后兼容：常量属性 ───────────────────────────────────────────

## @deprecated 使用 MineGameConstants.MINERAL_NAMES 代替
## 矿物类型到显示名称的映射
var mineral_names: Dictionary:
	get:
		# 使用旧枚举值作为键，保持向后兼容
		return {
			MineralType.none: "stone",
			MineralType.white: "iron",
			MineralType.gold: "gold",
			MineralType.blue: "diamond",
			MineralType.red: "blood",
			MineralType.lifter: "lifter",
			MineralType.trapdoor: "trapdoor",
		}

## @deprecated 使用 MineGameConstants.MINERAL_COORDS 代替
## 矿物类型到 TileSet 图块坐标的映射
var mineral_coord: Dictionary:
	get:
		return {
			MineralType.none: Vector2i(3, 4),
			MineralType.white: Vector2i(1, 9),
			MineralType.gold: Vector2i(2, 5),
			MineralType.blue: Vector2i(2, 8),
			MineralType.red: Vector2i(5, 5),
			MineralType.trapdoor: Vector2i(4, 4),
			MineralType.lifter: Vector2i(7, 0),
			MineralType.cover: Vector2i(5, 9),
			MineralType.hide: Vector2i(3, 5),
		}

# ── 向后兼容：可变状态属性 ───────────────────────────────────────

## @deprecated 使用 state.mine_points 代替
## 矿物挖掘获得的分数
var mine_points: Dictionary:
	get:
		return state.mine_points
	set(v):
		state.mine_points = v

## @deprecated 使用 state.mine_costs 代替
## 矿物挖掘消耗的行动点
var mine_cost: Dictionary:
	get:
		return state.mine_costs
	set(v):
		state.mine_costs = v

## @deprecated 使用 state.player_resources 代替
## 玩家拥有的矿物资源字典
var player_assets: Dictionary:
	get:
		return _get_player_assets_dict()
	set(v):
		_set_player_assets_dict(v)

## @deprecated 使用 state.max_ap 代替
## 最大行动点数
var max_ap: int:
	get:
		return state.max_ap
	set(v):
		state.max_ap = v

## @deprecated 使用 state.axe_level 代替
## 镐子升级等级
var axe_level: int:
	get:
		return state.axe_level
	set(v):
		state.axe_level = v

## @deprecated 使用 state.heal_level 代替
## 治疗升级等级
var heal_level: int:
	get:
		return state.heal_level
	set(v):
		state.heal_level = v

## @deprecated 使用 state.health_level 代替
## 生命值升级等级
var health_level: int:
	get:
		return state.health_level
	set(v):
		state.health_level = v

## @deprecated 使用 state.layer_heal 代替
## 下层恢复的行动点数
var layer_heal: int:
	get:
		return state.layer_heal
	set(v):
		state.layer_heal = v

## @deprecated 使用 config.get_cave_rect() 代替
## 洞穴网格区域
var cave_size: Rect2i:
	get:
		return config.get_cave_rect()

## @deprecated 使用 config.mineral_move_duration 代替
## 矿石移动动画持续时间
var move_interval: float:
	get:
		return config.mineral_move_duration

## @deprecated 使用 state.axe_level 代替（旧名称兼容）
## 镐子效率等级（与 axe_level 相同）
var pickaxe_level: int:
	get:
		return state.axe_level
	set(v):
		state.axe_level = v


# ── 生命周期 ─────────────────────────────────────────────────────

func _ready() -> void:
	# 实例化新模块
	config = MineGameConfig.new()
	state = MineGameState.new()
	events = EventSystem.new()

	# 将需要节点树的模块加为子节点
	state.name = "MineGameState"
	events.name = "EventSystem"
	add_child(state)
	add_child(events)

	# 注册全局事件
	events.register_event("label_changed")
	events.register_event("resource_changed")


# ── 辅助方法 ─────────────────────────────────────────────────────

## 将 ResourceManager 数据转换为旧版 player_assets 字典格式
## 使用旧枚举值作为键，确保向后兼容
func _get_player_assets_dict() -> Dictionary:
	var result: Dictionary = {}
	result[MineralType.white] = state.player_resources.get_resource(MineralType.white)
	result[MineralType.gold] = state.player_resources.get_resource(MineralType.gold)
	result[MineralType.blue] = state.player_resources.get_resource(MineralType.blue)
	result[MineralType.red] = state.player_resources.get_resource(MineralType.red)
	return result


## 从旧版 player_assets 字典格式设置 ResourceManager 数据
func _set_player_assets_dict(assets: Dictionary) -> void:
	for type in assets:
		var current: int = state.player_resources.get_resource(type)
		var target: int = assets[type]
		if target > current:
			state.player_resources.add_resource(type, target - current)
		elif target < current:
			state.player_resources.consume_resource(type, current - target)
