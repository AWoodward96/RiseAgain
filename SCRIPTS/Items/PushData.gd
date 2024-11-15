extends Resource
class_name PushData

#@export var tilePosition : Vector2i
@export var overrideActionDirection : bool = false
@export var pushDirectionOverride : GameSettingsTemplate.Direction
@export var pushAmount : int = 1
@export var carryLimit : int = 2 		# How many Units can stack up before stopping
