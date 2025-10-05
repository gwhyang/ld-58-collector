extends Control

signal exit_upgrade

const axe_upgrade:Array[Dictionary] = [
	{"describtion":"Stronger pixaxe!",
	"costs":{'iron':5,'gold':0,'diamond':0,'blood':0}
	},
	{"describtion":"Stronger pixaxe!",
	"costs":{'iron':5,'gold':10,'diamond':0,'blood':0}
	},
	{"describtion":"Stronger pixaxe!",
	"costs":{'iron':10,'gold':20,'diamond':20,'blood':0}
	},
	]
const heal_upgrade:Array[Dictionary] = [
	{"describtion":"Heals 1 more when downstairs",
	"costs":{'iron':0,'gold':0,'diamond':0,'blood':10}
	},
	{"describtion":"Heals 1 more when downstairs",
	"costs":{'iron':0,'gold':0,'diamond':5,'blood':30}
	},
	{"describtion":"Heals 1 more when downstairs",
	"costs":{'iron':0,'gold':0,'diamond':10,'blood':60}
	},
	{"describtion":"Heals 1 more when downstairs",
	"costs":{'iron':0,'gold':0,'diamond':15,'blood':80}
	},
	{"describtion":"Heals 1 more when downstairs",
	"costs":{'iron':0,'gold':0,'diamond':20,'blood':80}
	},
	]
const health_upgrade:Array[Dictionary] = [
	{"describtion":"1 more max action points per run",
	"costs":{'iron':5,'gold':0,'diamond':0,'blood':5}
	},
	{"describtion":"More max action points per run",
	"costs":{'iron':20,'gold':5,'diamond':0,'blood':5}
	},
	{"describtion":"More max action points per run",
	"costs":{'iron':40,'gold':12,'diamond':0,'blood':5}
	},
	{"describtion":"More max action points per run",
	"costs":{'iron':60,'gold':20,'diamond':0,'blood':5}
	},
	]

@onready var axe: PanelContainer = $HBoxContainer/axe
@onready var heal: PanelContainer = $HBoxContainer/heal
@onready var health: PanelContainer = $HBoxContainer/health



func _ready() -> void:
	update_wealth()
	axe.analyze(axe_upgrade[Game.axe_level])
	heal.analyze(heal_upgrade[Game.heal_level])
	health.analyze(health_upgrade[Game.health_level])
	
	axe.try_upgrade.connect(try_up_axe)
	heal.try_upgrade.connect(try_up_heal)
	health.try_upgrade.connect(try_up_health)
		
func try_up_heal():
	if Game.heal_level >= heal_upgrade.size():
		return
	if try_cost(heal_upgrade[Game.heal_level]["costs"]):
		add_heal()
		Game.heal_level +=1
		if Game.heal_level >= heal_upgrade.size():
			heal.hide()
		else: heal.analyze(heal_upgrade[Game.heal_level])
	
func try_up_axe():
	
	if Game.axe_level >= axe_upgrade.size():
		return
	if try_cost(axe_upgrade[Game.axe_level]["costs"]):
		add_pixaxe()
		Game.axe_level +=1
		if Game.axe_level >= axe_upgrade.size():
			axe.hide()
		else: axe.analyze(axe_upgrade[Game.axe_level])
	
func try_up_health():
	if Game.health_level >= health_upgrade.size():
		return
	if try_cost(health_upgrade[Game.health_level]["costs"]):
		add_health()
		Game.health_level +=1
		if Game.health_level >= health_upgrade.size():
			health.hide()
		else: health.analyze(health_upgrade[Game.health_level])

func add_heal():
	Game.layer_heal += 1
	

func add_pixaxe():
	match Game.axe_level:
		0:
			Game.mine_cost[Game.none] -= 1
		1:
			Game.mine_cost[Game.white] -= 1
		2:
			Game.mine_cost[Game.gold] -= 1
	
func add_health():
	Game.max_ap += 2

func update_wealth():
	for type in Game.player_assets:
		EventBus.change_label(Game.mineral_names[type],str(Game.player_assets[type]))

func try_cost(cost:Dictionary) -> bool:
	var result = Game.player_assets.duplicate()
	
	for key in Game.player_assets:
		result[key] -= cost[Game.mineral_names[key]]
		if result[key] <0:
			return false
	
	Game.player_assets = result
	update_wealth()
	return true


func _on_exit_pressed() -> void:
	exit_upgrade.emit()
