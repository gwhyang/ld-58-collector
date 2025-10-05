extends TileMapLayer

const NUMBER_HINTOR = preload("uid://dw7tufodyiqbo")

@onready var mine_game: Node = $"../.."


var cell2hintor:Dictionary = {}

func _ready() -> void:
	var posi := Game.cave_size.position
	var size := Game.cave_size.size
	for i in size.x:
		for j in size.y:
			var hintor = NUMBER_HINTOR.instantiate()
			var cell = Vector2i(i,j) + posi
			
			hintor.cell_posi = cell
			hintor.num = 0
			hintor.position = map_to_local(cell) - Vector2(tile_set.tile_size/2)
			
			mine_game.change_hint.connect(hintor.change_num)
			
			hintor.hide()
			add_child(hintor)

#func place_number(cell:Vector2i,num:int):
	#if cell2hintor.get(cell,null):
		#if num<0
		#
		#cell2hintor[cell] = num
	#
	#var hintor = NUMBER_HINTOR.instantiate()
	#hintor.cell_posi = cell
	#hintor.num = num
	#hintor.position = map_to_local(cell)
	#
	#erase_hint.connect(func(cell:Vector2i):
		#if cell == hintor.cell_posi:
			#hintor.queue_free())
	#change_hint.connect(func(cell:Vector2i,num:int):
		#if cell == hintor.cell_posi:
			#hintor.num = num)
	#cell2hintor[cell] = hintor
	#
	#add_child(hintor)
