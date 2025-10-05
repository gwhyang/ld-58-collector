extends Node

var preserved:Dictionary
var grid_size:Vector2i
var default_value:int = -1

var weight_pairs:Dictionary

func generate_cave() -> Dictionary:
	var cave_grid :={}
	var weights := weight_normalized(weight_pairs)
	for cell in preserved:
		if cell.x > grid_size.x or cell.y > grid_size.y:
			push_error("preserved cell %d out of boundary" %cell)
			continue
		cave_grid[cell] = preserved[cell]
	
	for i in grid_size.x:
		for j in grid_size.y:
			var cell = Vector2i(i,j)
			if preserved.has(cell):
				continue
			var radf = randf()
			for mineral in weights:
				radf -= weights[mineral]
				if radf<=0:
					cave_grid[cell] = mineral
					break
	
	return cave_grid



func weight_normalized(dict:Dictionary) -> Dictionary:
	var result:=dict.duplicate()
	var total_weight:float = 0
	
	for key in dict:
		var weight := dict[key] as float
		total_weight += weight
	
	for key in dict:
		var weight := dict[key] as float
		result[key] = weight / total_weight
	
	return result
