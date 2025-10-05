extends Panel

@export var cell_posi:Vector2i
@export var num:int

@onready var label: Label = $Label

const NUMBER_HINTOR = preload("uid://dw7tufodyiqbo")


func _ready() -> void:
	label.text = str(num)

func change_num(cell:Vector2i,num:int):
	if not cell == cell_posi:
		return
		
	label.text = str(num)
	if num<=0:
		hide()
		return
	show()
