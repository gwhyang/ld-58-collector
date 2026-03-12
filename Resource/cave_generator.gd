extends Node
# Procedural cave generation system with weighted mineral distribution

var preserved:Dictionary  # Pre-placed cells (entrance, exit, etc.)
var grid_size:Vector2i  # Size of the cave grid
var default_value:int = -1

var weight_pairs:Dictionary  # Mineral spawn weights for this level

## Generates a cave grid with minerals distributed according to weights
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



## Normalizes weight values so they sum to 1.0
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
