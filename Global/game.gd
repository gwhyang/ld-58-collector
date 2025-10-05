extends Node

enum {none,white,black,gold,blue,brown,red,trapdoor,lifter,cover,hide}
const cave_size:Rect2i = Rect2i(Vector2i.ZERO,Vector2i(12,10))
const mineral_names:Dictionary={
	none:"stone",
	white:"iron",
	gold:"gold",
	blue:"diamond",
	red:"blood",
	lifter:"lifter",
	trapdoor:"trapdoor",
}

const minral_coord:Dictionary={
	none:Vector2i(3,4),
	white:Vector2i(1,9),
	gold:Vector2i(2,5),
	blue:Vector2i(2,8),
	red:Vector2i(5,5),
	trapdoor:Vector2i(4,4),
	lifter:Vector2i(7,0),
	cover:Vector2i(5,9),
	hide:Vector2i(3,5)
}

var mine_points:Dictionary={
	none:1,
	white:2,
	gold:7,
	blue:9,
	red:5,
	lifter:0,
	trapdoor:100,
}

var mine_cost:Dictionary={
	none:1,
	white:2,
	gold:7,
	blue:9,
	red:0,#Here means how many it heals
	lifter:0,
	trapdoor:0,
}

var player_assets:Dictionary={
	white:0,
	gold:0,
	blue:0,
	red:0
}

var layer_heal:int = 2
var axe_level:int = 0
var max_ap:int = 10

var pixaxe_level:int = 0
var heal_level:int = 0
var health_level:int = 0
