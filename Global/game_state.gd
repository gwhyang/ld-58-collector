class_name MineGameState
extends Node
## 游戏运行时状态管理
##
## 管理游戏中的可变状态，包括玩家资源、升级等级、
## 挖掘成本和矿物价值。所有可被升级修改的数据都在这里管理。

# ── 信号 ──────────────────────────────────────────────────────
## 升级等级发生变化时发出
## @param upgrade_type 升级类型名称（"axe" / "heal" / "health"）
## @param new_level 变化后的等级
signal upgrade_level_changed(upgrade_type: String, new_level: int)

# ── 玩家资源 ──────────────────────────────────────────────────
## 资源管理器实例，管理玩家拥有的各种矿物
var player_resources: ResourceManager

# ── 可变的挖掘数据（受升级影响）────────────────────────────────
## 挖掘消耗字典，可被镐子升级修改
var mine_costs: Dictionary = {}

## 矿物价值字典，可被升级修改
var mine_points: Dictionary = {}

# ── 升级等级 ──────────────────────────────────────────────────
## 镐子升级等级
var axe_level: int = 0:
	set(v):
		if v == axe_level:
			return
		axe_level = v
		upgrade_level_changed.emit("axe", v)

## 治疗升级等级
var heal_level: int = 0:
	set(v):
		if v == heal_level:
			return
		heal_level = v
		upgrade_level_changed.emit("heal", v)

## 生命值升级等级
var health_level: int = 0:
	set(v):
		if v == health_level:
			return
		health_level = v
		upgrade_level_changed.emit("health", v)

## 最大行动点数
var max_ap: int = 7

## 下层恢复的行动点数
var layer_heal: int = 2


# ── 初始化 ────────────────────────────────────────────────────
func _init() -> void:
	player_resources = ResourceManager.new()
	# 用矿物类型初始化资源（铁、金、钻石、血矿）
	player_resources.initialize_resources({
		MineGameConstants.MineralType.WHITE: 0,
		MineGameConstants.MineralType.GOLD:  0,
		MineGameConstants.MineralType.BLUE:  0,
		MineGameConstants.MineralType.RED:   0,
	})
	# 从常量复制基础数据到可变字典
	mine_costs = MineGameConstants.BASE_MINE_COSTS.duplicate()
	mine_points = MineGameConstants.BASE_MINERAL_POINTS.duplicate()


func _ready() -> void:
	# 将 ResourceManager 加为子节点以启用信号系统
	add_child(player_resources)


# ── 升级方法 ──────────────────────────────────────────────────

## 应用镐子升级效果
## 根据当前等级降低对应矿物的挖掘消耗
func apply_pickaxe_upgrade() -> void:
	match axe_level:
		0:
			mine_costs[MineGameConstants.MineralType.NONE] -= 1
		1:
			mine_costs[MineGameConstants.MineralType.WHITE] -= 1
		2:
			mine_costs[MineGameConstants.MineralType.GOLD] -= 1
	axe_level += 1


## 应用治疗升级效果
## 增加下层恢复的行动点数
func apply_heal_upgrade() -> void:
	layer_heal += 1
	heal_level += 1


## 应用生命值升级效果
## 增加最大行动点数
func apply_health_upgrade() -> void:
	max_ap += 2
	health_level += 1


# ── 重置 ──────────────────────────────────────────────────────

## 重置所有可变状态（用于开始新游戏）
func reset_state() -> void:
	# 重置升级等级
	axe_level = 0
	heal_level = 0
	health_level = 0

	# 重置数值
	max_ap = 7
	layer_heal = 2

	# 从常量重新复制基础数据
	mine_costs = MineGameConstants.BASE_MINE_COSTS.duplicate()
	mine_points = MineGameConstants.BASE_MINERAL_POINTS.duplicate()

	# 重置玩家资源
	player_resources.reset_resources()
