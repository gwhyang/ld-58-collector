extends Node

@export var label_name:String
@onready var label:Label = get_parent()

func _ready() -> void:
	if not label_name:
		label_name = label.name
	
	EventBus.label_changed.connect(
		func(l_name:String,text:String):
			if label_name != l_name:
				return
			label.text = text
	)
