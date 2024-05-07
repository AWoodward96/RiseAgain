extends Node2D
class_name UnitVisual

@export var AnimationCTRL : AnimationPlayer
var MyUnit : UnitInstance

func Initialize(_unit : UnitInstance) :
	MyUnit = _unit


func SetActivated(_activated : bool):
	if _activated:
		AnimationCTRL.play(GetAnimString("Activated"))
	else:
		AnimationCTRL.play(GetAnimString("Unactivated"))

func GetAnimString(_suffix : String):
	var animStr = ""
	match(MyUnit.UnitAllegiance):
		GameSettings.TeamID.ALLY:
			animStr = "Ally"
		GameSettings.TeamID.ENEMY:
			animStr = "Enemy"
		GameSettings.TeamID.NEUTRAL:
			animStr = "Neutral"

	return "Unit" + animStr + "/" + _suffix
