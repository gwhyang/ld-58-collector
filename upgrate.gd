extends PanelContainer

@onready var label: Label = $VBoxContainer/Label
@onready var iron: Label = $VBoxContainer/HBoxContainer/HBoxContainer2/iron
@onready var gold: Label = $VBoxContainer/HBoxContainer/HBoxContainer3/gold
@onready var diamond: Label = $VBoxContainer/HBoxContainer/HBoxContainer4/diamond
@onready var blood: Label = $VBoxContainer/HBoxContainer/HBoxContainer5/blood
@onready var cover: TextureRect = $cover
@onready var up_ani: AnimationPlayer = $up_ani


signal try_upgrade


func analyze(item_data:Dictionary):
	var desc  = item_data.get("describtion","") as String
	var requ = item_data.get("costs","") as Dictionary
	print(1)
	
	if not (desc and requ):
		push_error("asdffe")
		print(desc)
		print(requ)
		return
	
	
	label.text = desc
	for key in requ:
		var cost_label = get(key) as Label
		cost_label.text = str(requ[key])
	


func _on_button_pressed() -> void:
	try_upgrade.emit()
