extends Area2D
class_name TopdownTeleporter

@export var Destination : Node2D
@export var DestinationEnvironment : TopdownEnvironment # If this is null, we're teleporting between the same environment. If this is not null, we're teleporting to a new environment.

func _ready():
	body_entered.connect(OnBodyEntered)


func OnBodyEntered(_body : Node2D):
	if _body is TopDownPlayer:
		_body.UseTeleporter(self)
		pass
