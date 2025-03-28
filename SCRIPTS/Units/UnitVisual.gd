extends Node2D
class_name UnitVisual

@export var AnimationCTRL : AnimationPlayer
@export var AnimationWorkComplete : bool = false
var sprite : Sprite2D
var visual : AnimatedSprite2D
var MyUnit : UnitInstance




func Initialize(_unit : UnitInstance) :
	MyUnit = _unit
	visual = get_node_or_null("Visual")
	sprite = get_node_or_null("Sprite2D")
	RefreshAllegience()

func RefreshAllegience():
	if MyUnit != null && visual != null:
		if AnimationWorkComplete:
			pass
		else:
			match MyUnit.UnitAllegiance:
				GameSettingsTemplate.TeamID.ALLY:
					sprite.modulate = GameManager.GameSettings.Alpha_AlliedUnitColor
				GameSettingsTemplate.TeamID.ENEMY:
					sprite.modulate = GameManager.GameSettings.Alpha_EnemyUnitColor
				GameSettingsTemplate.TeamID.NEUTRAL:
					sprite.modulate = GameManager.GameSettings.Alpha_NeutralUnitColor


func SetActivated(_activated : bool):
	if _activated:
		sprite.self_modulate = Color.WHITE
		#if AnimationCTRL.has_animation(GetAnimString("Activated")):
			#AnimationCTRL.play(GetAnimString("Activated"))
	else:
		sprite.self_modulate = GameManager.GameSettings.Alpha_DeactivatedModulate
		#if AnimationCTRL.has_animation(GetAnimString("Unactivated")):
			#AnimationCTRL.play(GetAnimString("Unactivated"))

func PlayAnimation(_animString : String, _uniformTransition : bool, _animSpeed : float, _fromEnd : bool):
	if AnimationWorkComplete:
		AnimationCTRL.play(_animString)
		# Change the animation with keeping the frame index and progress.
		#if _uniformTransition:
			#var current_frame = visual.get_frame()
			#var current_progress = visual.get_frame_progress()
			#visual.play(_animString)
			#visual.set_frame_and_progress(current_frame, current_progress)
		#else:
			#visual.play(_animString)

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
