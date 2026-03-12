extends MineGameBase
## 矿洞收集者 - 具体游戏实现
## 继承 MineGameBase，实现具体的矿物挖掘逻辑

const RED_HEAL_AMOUNT:int = 5  # How many action points blood ore restores
const NEIGHBOR_OFFSETS_3X3:Array[Vector2i] = [
	Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1),
	Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
]
const NEIGHBOR_OFFSETS_5X5:Array[Vector2i] = [
	Vector2i(-2,-2), Vector2i(-1,-2), Vector2i(0,-2), Vector2i(1,-2), Vector2i(2,-2),
	Vector2i(-2,-1), Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1), Vector2i(2,-1),
	Vector2i(-2, 0), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
	Vector2i(-2, 1), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
	Vector2i(-2, 2), Vector2i(-1, 2), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)
]
const NEIGHBOR_OFFSETS_CROSS:Array[Vector2i] = [
	Vector2i(-1,0), Vector2i(1,0), Vector2i(0,1), Vector2i(0,-1)
]
## 3x3 外围的 12 个相邻单元格（不包含四个角）
const NEIGHBOR_OFFSETS_OUTER_RING: Array[Vector2i] = [
	# 上侧 3 格
	Vector2i(-1, -2), Vector2i(0, -2), Vector2i(1, -2),
	# 左侧 3 格
	Vector2i(-2, -1), Vector2i(-2, 0), Vector2i(-2, 1),
	# 右侧 3 格
	Vector2i(2, -1), Vector2i(2, 0), Vector2i(2, 1),
	# 下侧 3 格
	Vector2i(-1, 2), Vector2i(0, 2), Vector2i(1, 2)
]

@export var min_dis:int = 5  # Min distance between trapdoor and lifter
@export var enable:bool = true
@export var mine_icons:Dictionary = {Game.MineralType.white:NodePath(),Game.MineralType.gold:NodePath(),Game.MineralType.blue:NodePath(),Game.MineralType.red:NodePath()}

# 注意：以下变量已在 MineGameBase 中定义：
# - action_points, max_action_points（行动点系统）
# - gained_minerals（收集的矿物）
# - mine_state（挖矿状态，原 mine_state）
# - current_level（当前关卡深度）
var level_weights:Array = [
	{Game.MineralType.none:27,
	Game.MineralType.white:11,
	Game.MineralType.gold:1,
	Game.MineralType.blue:0,
	Game.MineralType.red:9},{
	Game.MineralType.none:20,
	Game.MineralType.white:12,
	Game.MineralType.gold:4,
	Game.MineralType.blue:0,
	Game.MineralType.red:5},{
	Game.MineralType.none:20,
	Game.MineralType.white:10,
	Game.MineralType.gold:14,
	Game.MineralType.blue:1,
	Game.MineralType.red:4},{
	Game.MineralType.none:16,
	Game.MineralType.white:2,
	Game.MineralType.gold:16,
	Game.MineralType.blue:4,
	Game.MineralType.red:4}
]

var to_label_cell:Vector2i = -Vector2i.ONE  # Cell to place label on
var to_label_num:int = -1  # Number to place on label
var mine_ui_posi:Dictionary = {}  # UI positions for mineral icons

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
@onready var fail_particle: GPUParticles2D = $UI/fail_particle
@onready var fail_label: Label = $UI/faile_label

signal change_hint(cell:Vector2i,num:int)
signal change_reminder(cell:Vector2i,num:int)
signal change_label(cell:Vector2i,num:int)
# 注意：game_exit 和 game_enter 信号已在 MineGameBase 中定义

func _ready() -> void:
	super._ready()  # 调用 MineGameBase._ready()

	# 设置网格图层引用（GridGameBase 需要）
	grid_layer = mine
	cover_layer = coverer
	hint_layer = message

	# 连接信号处理 UI 更新
	action_points_changed.connect(_on_action_points_changed)

	initial()
	await get_tree().process_frame
	update_ui_posi()

func initial():
	game_enter.emit()

	max_action_points = Game.max_ap
	action_points = max_action_points
	for mineral in Game.mine_points:
		gained_minerals[mineral] = 0
	notify_mineral_changed()

	cave_generator.grid_size = Game.cave_size.size
	mine_state = MineState.WAITING_START
	recover()

## 行动点变化时更新 UI
func _on_action_points_changed(current: int, maximum: int) -> void:
	EventBus.change_label("ap", str(current) + "/" + str(maximum))

## 更新关卡标签
func _update_level_label() -> void:
	level_label.text = str(current_level)

func mouse_dig(mouse_posi:Vector2) -> void:
	var dug_cell := mine.local_to_map(mine.to_local(mouse_posi))
	try_dig(dug_cell)

func try_dig(dug_cell:Vector2i) -> void:
	match mine_state:
		MineState.WAITING_START:
			start_new_level(dug_cell)
		MineState.PROCESSING:
			process_dig_action(dug_cell)
		MineState.FAIL:
			restart_game()

## Initializes a new level when the player clicks to start
func start_new_level(start_cell:Vector2i) -> void:
	if not Game.cave_size.has_point(start_cell):
		return

	# Convert world coordinates to grid coordinates
	var grid_start:Vector2i = start_cell - Game.cave_size.position
	var preserved:Dictionary = {}
	preserved[grid_start] = Game.MineralType.lifter

	# Generate trapdoor at minimum distance from entrance (in grid coordinates)
	var grid_trapdoor:Vector2i = generate_trapdoor_position(grid_start)
	var world_trapdoor:Vector2i = grid_trapdoor + Game.cave_size.position
	coverer.set_cell(world_trapdoor, 0, Game.mineral_coord[Game.MineralType.trapdoor])

	# Create preserved path between entrance and trapdoor (in grid coordinates)
	create_preserved_path(grid_start, grid_trapdoor, preserved)
	preserved[grid_trapdoor] = Game.MineralType.trapdoor

	# Configure cave generation
	cave_generator.preserved = preserved
	cave_generator.weight_pairs = level_weights[mini(current_level, level_weights.size() - 1)]

	new_layer()
	mine_state = MineState.PROCESSING
	_update_ui_for_state(MineState.PROCESSING)

## Generates a trapdoor position at minimum distance from start (in grid coordinates)
func generate_trapdoor_position(grid_start:Vector2i) -> Vector2i:
	var trapdoor_cell:Vector2i = Vector2i.ZERO
	# Keep generating until we find a position far enough from start
	while absi(trapdoor_cell.x - grid_start.x) + absi(trapdoor_cell.y - grid_start.y) < min_dis:
		trapdoor_cell.x = randi_range(0, Game.cave_size.size.x - 1)
		trapdoor_cell.y = randi_range(0, Game.cave_size.size.y - 1)
	return trapdoor_cell

## Creates a preserved stone path between two points (in grid coordinates)
func create_preserved_path(from:Vector2i, to:Vector2i, preserved:Dictionary) -> void:
	var dir:Vector2i = to - from
	dir.x = signi(dir.x)
	dir.y = signi(dir.y)

	var current:Vector2i = from
	while current != to:
		var step_axis:int = randi_range(0, 1)
		if current[step_axis] == to[step_axis]:
			step_axis ^= 1
		current[step_axis] += dir[step_axis]
		preserved[current] = Game.MineralType.none

## Restarts the game after a fail
func restart_game() -> void:
	current_level = 0
	_update_level_label()
	recover()
	mine_state = MineState.WAITING_START
	_update_ui_for_state(MineState.WAITING_START)
	action_points = max_action_points

## Processes digging action in normal gameplay
func process_dig_action(dug_cell:Vector2i) -> void:
	# Check if cell is covered (blocked)
	if dug_cell in coverer.get_used_cells():
		SoundManager.sfx_play("fail_dig")
		return

	# Get cell data
	var data:TileData = mine.get_cell_tile_data(dug_cell)
	if not data:
		return

	var type:int = data.get_custom_data("mine_type") as int

	# Check if mineral is already revealed (can be picked up)
	if not dug_cell in hider.get_used_cells():
		handle_mineral_pickup(type, dug_cell)
	else:
		handle_covered_dig(type, dug_cell)

## Handles picking up an already revealed mineral
func handle_mineral_pickup(type:int, cell:Vector2i) -> void:
	# Handle special minerals
	if type == Game.MineralType.trapdoor:
		recover()
		mine_state = MineState.WAITING_START
		action_points += Game.layer_heal
		current_level += 1
		_update_level_label()
		return

	if type == Game.MineralType.lifter:
		exit_mine()
		return

	if type == Game.MineralType.red:
		action_points += RED_HEAL_AMOUNT

	# Remove mineral from map
	mine.erase_cell(cell)
	reminder_change(cell, 0)

	# Update mineral count
	gained_minerals[type] += 1

	# Update neighboring cells
	for offset in NEIGHBOR_OFFSETS_3X3:
		update_cell_message(cell + offset)

	pick_ani_and_notify(type, get_viewport().get_mouse_position())

	if type != Game.MineralType.none:
		SoundManager.sfx_play("pick_mineral")

## Handles digging a covered mineral (costs action points)
func handle_covered_dig(type:int, cell:Vector2i) -> void:
	action_points -= Game.mine_cost[type]

	if type == Game.MineralType.red:
		SoundManager.sfx_play("heal")

	if action_points < 0:
		game_fail()
		return

	# Reveal the cell
	hider.erase_cell(cell)
	label_change(cell, 0)

	# Remove surrounding covers
	for offset in NEIGHBOR_OFFSETS_CROSS:
		coverer.erase_cell(cell + offset)

func update_cell_message(cell:Vector2i) -> void:
	var cell_value:int = 0
	for offset in NEIGHBOR_OFFSETS_3X3:
		var neighbor_cell:Vector2i = cell + offset
		var data:TileData = mine.get_cell_tile_data(neighbor_cell)
		if data and data.has_custom_data("mine_type"):
			cell_value += Game.mine_points[data.get_custom_data("mine_type")]
	hint_change(cell, cell_value)

func _input(event: InputEvent) -> void:
	if not enable:
		return
	
	if event.is_action_pressed("dig_mouse"):
		mouse_dig(mine.get_global_mouse_position())
	if event.is_action_pressed("label"):
		var cell = mine.local_to_map(mine.to_local(mine.get_global_mouse_position()))
		if not cell in hider.get_used_cells():
			to_label_num = -1
			return
		to_label_cell = cell
		if try_label():
			SoundManager.sfx_play("place_label")
		
func game_fail() -> void:
	SoundManager.sfx_play("fail")
	mine_state = MineState.FAIL
	_update_ui_for_state(MineState.FAIL)
	fail_particle.restart()
	for key in gained_minerals:
		gained_minerals[key] = 0
	notify_mineral_changed()
	action_points = 0

## 根据状态更新 UI 显示
func _update_ui_for_state(state: MineState) -> void:
	match state:
		MineState.FAIL:
			labeler.hide()
			coverer.hide()
			hider.hide()
			reminder.hide()
			message.hide()
			fail_label.show()
		MineState.WAITING_START, MineState.PROCESSING:
			labeler.show()
			coverer.show()
			hider.show()
			reminder.show()
			message.show()
			fail_label.hide()

func exit_mine() -> void:
	# 将挖到的矿物添加到玩家资源（使用新的 ResourceManager API）
	for mineral in gained_minerals:
		if gained_minerals[mineral] > 0:
			Game.state.player_resources.add_resource(mineral, gained_minerals[mineral])
			gained_minerals[mineral] = 0
	notify_mineral_changed()
	game_exit.emit()
	current_level = 0
	_update_level_label()
	SoundManager.sfx_play("exit_mine")

func new_layer() -> void:
	var cave:Dictionary = cave_generator.generate_cave()
	for cell:Vector2i in cave:
		var type:int = cave[cell]
		var world_cell:Vector2i = cell + Game.cave_size.position

		mine.set_cell(world_cell, 0, Game.mineral_coord[type])
		reminder_change(world_cell, Game.mine_points[type])

		match type:
			Game.MineralType.lifter:
				# 清除 3x3 区域的 coverer 和 hider（相当于已被挖掘，显示矿物和信息）
				for offset in NEIGHBOR_OFFSETS_3X3:
					coverer.erase_cell(world_cell + offset)
					hider.erase_cell(world_cell + offset)
				# 清除外围 12 格的 coverer（可挖掘区域）
				for offset in NEIGHBOR_OFFSETS_OUTER_RING:
					coverer.erase_cell(world_cell + offset)
			Game.MineralType.trapdoor:
				coverer.set_cell(world_cell, 0, Game.mineral_coord[type])
				hider.erase_cell(world_cell)

func recover() -> void:
	for x in Game.cave_size.size.x:
		for y in Game.cave_size.size.y:
			var cell := Vector2i(x,y)
			coverer.set_cell(cell+Game.cave_size.position,0,Game.mineral_coord[Game.MineralType.cover])
			hider.set_cell(cell+Game.cave_size.position,0,Game.mineral_coord[Game.MineralType.hide])
			label_change(cell+Game.cave_size.position,0)

func notify_mineral_changed() -> void:
	for type in gained_minerals:
		EventBus.change_label(Game.mineral_names[type],str(gained_minerals[type]))

func try_label() -> bool:
	if to_label_cell != -Vector2i.ONE and to_label_num != -1:
		label_change(to_label_cell,to_label_num)
		to_label_cell = -Vector2i.ONE
		return true
	return false
	
func hint_change(cell:Vector2i,num:int) -> void:
	change_hint.emit(cell,num)

func reminder_change(cell:Vector2i,num:int) -> void:
	change_reminder.emit(cell,num)

func label_change(cell:Vector2i,num:int) -> void:
	change_label.emit(cell,num)

func update_ui_posi() -> void:
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

func pick_ani_and_notify(mine_type:int,from_posi:Vector2) -> void:
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
		notify_mineral_changed()
		)
	
func _on_label_selector_selected_num(num: int) -> void:
	if num == -1:
		to_label_cell = -Vector2i.ONE
		return
	to_label_num = num
