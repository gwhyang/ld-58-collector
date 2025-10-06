extends AnimationPlayer

func _ready() -> void:
	await get_parent().ready
	update_icon()
func update_icon():
	play(str(Game.axe_level))
	get_parent().resized.emit()
