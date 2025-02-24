extends Node2D
class_name UnitVisual

@export var AnimationCTRL : AnimationPlayer
var visual : AnimatedSprite2D
var MyUnit : UnitInstance


func Initialize(_unit : UnitInstance) :
	MyUnit = _unit
	visual = get_node_or_null("Visual")

func SetActivated(_activated : bool):
	if _activated:
		if AnimationCTRL.has_animation(GetAnimString("Activated")):
			AnimationCTRL.play(GetAnimString("Activated"))
	else:
		if AnimationCTRL.has_animation(GetAnimString("Unactivated")):
			AnimationCTRL.play(GetAnimString("Unactivated"))

func PlayAnimation(_animString : String, _uniformTransition : bool, _animSpeed : float, _fromEnd : bool):
	if visual != null:
		# Change the animation with keeping the frame index and progress.
		if _uniformTransition:
			var current_frame = visual.get_frame()
			var current_progress = visual.get_frame_progress()
			visual.play(_animString)
			visual.set_frame_and_progress(current_frame, current_progress)
		else:
			visual.play(_animString)

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
