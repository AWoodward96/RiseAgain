extends Node2D
class_name ResourceFlyer

@export var BurstDistance : int = 16
@export var BurstDuration : float = 0.75
@export var ToUIDuration : float = 1

func Burst(_origin : Vector2, _destination : Vector2):
	var tween = create_tween()

	pass
