extends Node2D
class_name Bastion

static var CurrentBastion : Bastion

@export var defaultEnvironment : PackedScene

@onready var environment_parent: Node2D = $EnvironmentParent

var environment : TopdownEnvironment


func _ready():
	CurrentBastion = self
	if defaultEnvironment != null:
		environment = defaultEnvironment.instantiate() as TopdownEnvironment
		environment_parent.add_child(environment)

	if PersistDataManager.universeData.bastionData.DayComplete:
		GenerateNewDay()
	pass

func GenerateNewDay():
	PersistDataManager.universeData.bastionData.GenerateTavernOccupants(3, [] as Array[UnitTemplate])
	PersistDataManager.universeData.bastionData.DayComplete = false
	PersistDataManager.SaveGame()

func ShutDown():
	if environment != null:
		environment.Shutdown()
	queue_free()
	pass
