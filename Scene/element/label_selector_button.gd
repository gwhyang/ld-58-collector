extends Button

@onready var label_selector: Control = $"../.."
@export var num:int
signal num_selected(num)

#func _ready() -> void:
	#if text:
		#return
	#text = str(num)

func _on_pressed() -> void:
	label_selector.selected_num.emit(num)
	accept_event()
