extends Node2D
class_name UnitVisual

@export var AnimationCTRL : AnimationPlayer
var MyUnit : UnitInstance

func Initialize(_unit : UnitInstance) :
	MyUnit = _unit

func SetActivated(_activated : bool):
	if _activated:
		if AnimationCTRL.has_animation(GetAnimString("Activated")):
			AnimationCTRL.play(GetAnimString("Activated"))
	else:
		if AnimationCTRL.has_animation(GetAnimString("Unactivated")):
			AnimationCTRL.play(GetAnimString("Unactivated"))

func GetAnimString(_suffix : String):
	var animStr = ""
	match(MyUnit.UnitAllegiance):
		GameSettingsTemplate.TeamID.ALLY:
			animStr = "Ally"
		GameSettingsTemplate.TeamID.ENEMY:
			animStr = "Enemy"
		GameSettingsTemplate.TeamID.NEUTRAL:
			animStr = "Neutral"

	return "Unit" + animStr + "Library/" + _suffix
