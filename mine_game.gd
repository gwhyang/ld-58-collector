extends Node

enum{on_start,processing,fail}
@export var min_dis:int = 5# Min distance between trapdoor and lifter
@export var max_ap:int = 10
@export var action_points:int = 10000000:
	set(v):
		if v == action_points:
			return
		if v >= max_ap:
			action_points = max_ap
		else: action_points = v
		
		EventBus.change_label("ap",str(action_points)+"/"+str(max_ap))
@export var enable:bool = true
@export var mine_icons:Dictionary = {Game.white:NodePath(),Game.gold:NodePath(),Game.blue:NodePath(),Game.red:NodePath()}

var gained_mineral:Dictionary
var level_state:int = on_start:
	set(v):
		if v == level_state:
			return
		match level_state:
			fail:
				labeler.show()
				coverer.show()
				hider.show()
				reminder.show()
				message.show()
				$UI/faile_label.hide()
		match v:
			fail:
				labeler.hide()
				coverer.hide()
				hider.hide()
				reminder.hide()
				message.hide()
				$UI/faile_label.show()
		level_state = v
		
var current_level:int = 0:
	set(v):
		if v == current_level:
			return
		current_level = v
		level_label.text = str(v)
var level_weights:Array = [
	{Game.none:27,
	Game.white:11,
	Game.gold:1,
	Game.blue:0,
	Game.red:9},{
	Game.none:20,
	Game.white:12,
	Game.gold:4,
	Game.blue:0,
	Game.red:5},{
	Game.none:20,
	Game.white:10,
	Game.gold:14,
	Game.blue:1,
	Game.red:4},{
	Game.none:16,
	Game.white:2,
	Game.gold:16,
	Game.blue:4,
	Game.red:4}
]

var to_label_cell:Vector2i = -Vector2i.ONE
var to_labe_num:int = -1
var mine_ui_posi:Dictionary={}

@onready var mine: TileMapLayer = $world/mine
@onready var coverer: TileMapLayer = $world/coverer
@onready var message: TileMapLayer = $world/message
@onready var reminder: TileMapLayer = $world/reminder
@onready var hider: TileMapLayer = $world/hider
@onready var labeler: TileMapLayer = $world/labeler
@onready var cave_generator: Node = %cave_generator
@onready var label_selector: Control = $UI/Label_selector
@onready var level_label: Label = $UI/VBoxContainer/current_level
@onready var ui: CanvasLayer = $UI

signal change_hint(cell:Vector2i,num:int)
signal change_reminder(cell:Vector2i,num:int)
signal change_label(cell:Vector2i,num:int)
signal game_exit
signal game_enter

var points:Array[Vector2]

func _ready() -> void:
	initial()
	await get_tree().process_frame
	update_ui_posi()

func initial():
	game_enter.emit()
	
	max_ap = Game.max_ap
	action_points = max_ap
	for mineral in Game.mine_points:
		gained_mineral[mineral] = 0
	notify_minernal_changed()
	
	
	cave_generator.grid_size = Game.cave_size.size
	level_state = on_start
	recover()

func mouse_dig(mouse_posi:Vector2):
	var dug_cell := mine.local_to_map(mine.to_local(mouse_posi))
	try_dig(dug_cell)

func try_dig(dug_cell:Vector2i):
	match level_state:
		on_start:
			if not Game.cave_size.has_point(dug_cell):
				return
			
			var preserved = {}
			preserved[dug_cell-Game.cave_size.position] = Game.lifter
			
			# set trap door
			var new_entrance:Vector2i = dug_cell
			while absi(new_entrance.x-dug_cell.x) + absi(new_entrance.y-dug_cell.y) < min_dis :
				new_entrance.x = randi_range(0,Game.cave_size.size.x-1)
				new_entrance.y = randi_range(0,Game.cave_size.size.y-1)
			coverer.set_cell(new_entrance,0,Game.minral_coord[Game.trapdoor])
			
			#Preserved path
			var dir:Vector2i = new_entrance - dug_cell
			dir.x = signi(dir.x)
			dir.y = signi(dir.y)
			
			while new_entrance != dug_cell:
				var step_axis:int = randi_range(0,1)
				if dug_cell[step_axis] == new_entrance[step_axis]:
					step_axis ^= 1
				dug_cell[step_axis] += dir[step_axis]
				preserved[dug_cell] = Game.none
			
			preserved[new_entrance] = Game.trapdoor
			cave_generator.preserved = preserved
			
			if current_level<level_weights.size():
				cave_generator.weight_pairs = level_weights[current_level]
			else:cave_generator.weight_pairs = level_weights[level_weights.size()-1]
			
			new_layer()
			level_state = processing
			return
			
		processing:
			pass
		fail:
			current_level = 0
			recover()
			level_state = on_start
			action_points = max_ap
			return
		
	if dug_cell in coverer.get_used_cells():
		print("dig blocked")
		SoundManager.sfx_play("fail_dig")
		return
	
	var data:=mine.get_cell_tile_data(dug_cell)
	if not data:
		print("dig empty")
		return
	
	
	var type = data.get_custom_data("mine_type") as int
	
	# Pick mineral
	if not dug_cell in hider.get_used_cells():
		if type == Game.trapdoor:
			recover()
			level_state = on_start
			action_points += Game.layer_heal
			current_level += 1
			return
		
		if type == Game.lifter:
			exit_mine()
			return
		
		if type == Game.red:
			action_points += 5
			
		mine.erase_cell(dug_cell)
		reminder_change(dug_cell,0)
		
		gained_mineral[type] +=1
		for i in [-1,0,1]:
			for j in [-1,0,1]:
				update_cell_massage(dug_cell+Vector2i(i,j))
		pick_ani_and_notify(type,get_viewport().get_mouse_position())
		
		if not type == Game.none:
			SoundManager.sfx_play("pick_mineral")
		return
		
	action_points -= Game.mine_cost[type]
	
	if type == Game.red:
		SoundManager.sfx_play("heal")
	if action_points < 0:
		game_fail()
		return
	
	hider.erase_cell(dug_cell)
	label_change(dug_cell,0)
	for offset:Vector2i in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,1),Vector2i(0,-1)]:
		coverer.erase_cell(offset+dug_cell)

func update_cell_massage(cell:Vector2i):
	var cell_value:int = 0
	for i in [-1,0,1]:
		for j in [-1,0,1]:
			var joint_cell = Vector2i(i,j)+cell
			var data = mine.get_cell_tile_data(joint_cell)
			if data:
				if data.has_custom_data("mine_type"):
					cell_value += Game.mine_points[data.get_custom_data("mine_type")]
	hint_change(cell,cell_value)

func _input(event: InputEvent) -> void:
	if not enable:
		return
	
	if event.is_action_pressed("dig_mouse"):
		mouse_dig(mine.get_global_mouse_position())
	if event.is_action_pressed("label"):
		var cell = mine.local_to_map(mine.to_local(mine.get_global_mouse_position()))
		if not cell in hider.get_used_cells():
			to_labe_num = -1
			return
		to_label_cell = cell
		if try_label():
			SoundManager.sfx_play("place_label")
		
func game_fail():
	level_state = fail
	for key in gained_mineral:
		gained_mineral[key] = 0
	notify_minernal_changed()
	action_points=0

func exit_mine():
	for mineral in Game.player_assets:
		Game.player_assets[mineral] += gained_mineral.get(mineral,0)
	for mineral in gained_mineral:
		gained_mineral[mineral] = 0
	notify_minernal_changed()
	game_exit.emit()
	current_level = 0
	SoundManager.sfx_play("exit_mine")

func new_layer():
	var cave = cave_generator.generate_cave()
	for cell:Vector2i in cave:
		var type = cave[cell]
		
		cell += Game.cave_size.position
		mine.set_cell(cell,0,Game.minral_coord[type])
		reminder_change(cell,Game.mine_points[type])
		match type:
			Game.lifter:
				for i in [-2,-1,0,1,2]:
					for j in [-2,-1,0,1,2]:
						coverer.erase_cell(Vector2i(i,j)+cell)
				for i in [-1,0,1]:
					for j in [-1,0,1]:
						hider.erase_cell(Vector2i(i,j)+cell)
			Game.trapdoor:
				coverer.set_cell(cell,0,Game.minral_coord[type])
				hider.erase_cell(cell)

func recover():
	for x in Game.cave_size.size.x:
		for y in Game.cave_size.size.y:
			var cell := Vector2i(x,y)
			coverer.set_cell(cell+Game.cave_size.position,0,Game.minral_coord[Game.cover])
			hider.set_cell(cell+Game.cave_size.position,0,Game.minral_coord[Game.hide])
			label_change(cell+Game.cave_size.position,0)

func notify_minernal_changed():
	for type in gained_mineral:
		EventBus.change_label(Game.mineral_names[type],str(gained_mineral[type]))

func try_label() -> bool:
	print(to_label_cell,to_labe_num)
	if to_label_cell != -Vector2i.ONE and to_labe_num != -1:
		label_change(to_label_cell,to_labe_num)
		to_label_cell = -Vector2i.ONE
		return true
	return false
	
func hint_change(cell:Vector2i,num:int):
	change_hint.emit(cell,num)

func reminder_change(cell:Vector2i,num:int):
	change_reminder.emit(cell,num)

func label_change(cell:Vector2i,num:int):
	change_label.emit(cell,num)

func update_ui_posi():
	var name2posi:Dictionary
	for child_container in $UI/points/VBoxContainer.get_children():
		var label = child_container.get_child(1) as Label
		var icon = child_container.get_child(0) as TextureRect
		name2posi[label.name] = icon.global_position + (icon.size/2.0)*icon.scale

	for type in Game.mineral_names:
		var posi = name2posi.get(Game.mineral_names[type],null)
		if not posi:
			continue
		mine_ui_posi[type] = posi
	print("updated ui position dict:",mine_ui_posi)

func pick_ani_and_notify(mine_type:int,from_posi:Vector2):
	var icon_path = mine_icons.get(mine_type)
	if not icon_path:
		return
	var posi = mine_ui_posi.get(mine_type)
	if not posi:
		return
	
	var mover = get_node(icon_path).duplicate() as Control
	
	mover.z_index += 2
	mover.position = from_posi - mover.scale*(mover.size/2.0)
	ui.add_child(mover)
	
	var target_scale :Vector2= mover.scale * 0.6
	posi -= (mover.size/2.0)*target_scale
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(mover,"position",posi,Game.move_interval)
	tween.parallel().tween_property(mover,"scale",target_scale,Game.move_interval)
	tween.tween_callback(func():
		mover.queue_free()
		notify_minernal_changed()
		)
	
func _on_label_selector_selected_num(num: int) -> void:
	if num == -1:
		to_label_cell = -Vector2i.ONE
		return
	to_labe_num = num
	print(num)
