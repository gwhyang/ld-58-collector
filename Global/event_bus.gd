extends Node

signal label_changed(label_name:String,text:String)

func change_label(label_name:String,text:String):
	label_changed.emit(label_name,text)
