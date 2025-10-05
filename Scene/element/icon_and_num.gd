extends HBoxContainer
class_name IconAndNum

@export var num_label: Label
@export var autohide:bool = true

func _ready() -> void:
	if not num_label:
		num_label = Label.new()
		add_child(num_label)

func change_num(num:int):
	num_label.text = str(num)
