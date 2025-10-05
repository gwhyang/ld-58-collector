extends TileMapLayer

const NUMBER_REMINDER = preload("uid://0p7er8kt1exh")

@onready var mine_game: Node = $"../.."

var cell2hintor:Dictionary = {}

func _ready() -> void:
	var posi := Game.cave_size.position
	var size := Game.cave_size.size
	for i in size.x:
		for j in size.y:
			var reminder = NUMBER_REMINDER.instantiate()
			var cell = Vector2i(i,j) + posi
			
			reminder.cell_posi = cell
			reminder.num = 0
			reminder.position = map_to_local(cell) - Vector2(tile_set.tile_size/2)
			
			mine_game.change_reminder.connect(reminder.change_num)
			
			reminder.hide()
			add_child(reminder)
