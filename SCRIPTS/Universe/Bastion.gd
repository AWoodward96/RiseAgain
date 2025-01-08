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
	pass

func ShutDown():
	if environment != null:
		environment.Shutdown()
	pass
