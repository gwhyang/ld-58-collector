class_name MineGameConstants
extends Node
## 游戏常量定义
##
## 包含矿物类型枚举、名称映射、TileSet坐标映射、
## 基础矿物价值和挖掘消耗等游戏核心常量。

# ── 矿物类型枚举 ──────────────────────────────────────────────
## 定义所有矿物和特殊方块的类型
enum MineralType {
	NONE,      ## 普通石头
	WHITE,     ## 铁矿
	BLACK,     ## 黑矿（未使用）
	GOLD,      ## 金矿
	BLUE,      ## 钻石
	BROWN,     ## 棕矿（未使用）
	RED,       ## 血矿（治疗）
	TRAPDOOR,  ## 陷阱门
	LIFTER,    ## 升降梯
	COVER,     ## 遮罩层
	HIDE,      ## 隐藏层
}

# ── 矿物名称映射 ──────────────────────────────────────────────
## 矿物类型到显示名称的映射，用于 UI 标签和事件通知
const MINERAL_NAMES: Dictionary = {
	MineralType.NONE:     "stone",
	MineralType.WHITE:    "iron",
	MineralType.GOLD:     "gold",
	MineralType.BLUE:     "diamond",
	MineralType.RED:      "blood",
	MineralType.LIFTER:   "lifter",
	MineralType.TRAPDOOR: "trapdoor",
}

# ── 矿物 TileSet 坐标映射 ─────────────────────────────────────
## 矿物类型到 TileSet 图块坐标的映射，用于渲染对应的图块
const MINERAL_COORDS: Dictionary = {
	MineralType.NONE:     Vector2i(3, 4),
	MineralType.WHITE:    Vector2i(1, 9),
	MineralType.GOLD:     Vector2i(2, 5),
	MineralType.BLUE:     Vector2i(2, 8),
	MineralType.RED:      Vector2i(5, 5),
	MineralType.TRAPDOOR: Vector2i(4, 4),
	MineralType.LIFTER:   Vector2i(7, 0),
	MineralType.COVER:    Vector2i(5, 9),
	MineralType.HIDE:     Vector2i(3, 5),
}

# ── 基础矿物价值 ──────────────────────────────────────────────
## 挖掘矿物获得的基础分数/价值，显示在提示数字上
const BASE_MINERAL_POINTS: Dictionary = {
	MineralType.NONE:     1,
	MineralType.WHITE:    2,
	MineralType.GOLD:     7,
	MineralType.BLUE:     9,
	MineralType.RED:      5,
	MineralType.LIFTER:   0,
	MineralType.TRAPDOOR: 100,
}

# ── 基础挖掘消耗 ──────────────────────────────────────────────
## 挖掘矿物消耗的基础行动点数
## 注意：RED 的值表示治疗量而非消耗
const BASE_MINE_COSTS: Dictionary = {
	MineralType.NONE:     1,
	MineralType.WHITE:    2,
	MineralType.GOLD:     7,
	MineralType.BLUE:     9,
	MineralType.RED:      0,   # 此处表示治疗量
	MineralType.LIFTER:   0,
	MineralType.TRAPDOOR: 0,
}
