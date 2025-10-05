extends AnimationPlayer

func _ready() -> void:
	await get_parent().ready
	play(str(Game.axe_level))
	get_parent().resized.emit()
