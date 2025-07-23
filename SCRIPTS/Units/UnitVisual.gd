extends Node2D
class_name UnitVisual

@export var AnimationCTRL : AnimationPlayer
@export var AnimationWorkComplete : bool = false
@export var SubmergedParent : Node2D
var sprite : Sprite2D
var visual : AnimatedSprite2D
var MyUnit : UnitInstance

var take_damage_step : int = 0


func Initialize(_unit : UnitInstance) :
	MyUnit = _unit
	visual = get_node_or_null("Visual")
	sprite = get_node_or_null("Sprite2D")
	RefreshAllegience()

func RefreshAllegience():
	if MyUnit != null && visual != null:
		if AnimationWorkComplete:
			match MyUnit.UnitAllegiance:
				GameSettingsTemplate.TeamID.ALLY:
					visual.material.set_shader_parameter("palette_index", 1)
				GameSettingsTemplate.TeamID.ENEMY:
					visual.material.set_shader_parameter("palette_index", 2)
				GameSettingsTemplate.TeamID.NEUTRAL:
					visual.material.set_shader_parameter("palette_index", 3)

		else:
			match MyUnit.UnitAllegiance:
				GameSettingsTemplate.TeamID.ALLY:
					sprite.modulate = GameManager.GameSettings.Alpha_AlliedUnitColor
				GameSettingsTemplate.TeamID.ENEMY:
					sprite.modulate = GameManager.GameSettings.Alpha_EnemyUnitColor
				GameSettingsTemplate.TeamID.NEUTRAL:
					sprite.modulate = GameManager.GameSettings.Alpha_NeutralUnitColor


func SetActivated(_activated : bool):
	if AnimationWorkComplete:
		visual.material.set_shader_parameter("grey_scale", !_activated)
	else:
		if _activated:
			sprite.self_modulate = Color.WHITE
			PlayAnimation(UnitSettingsTemplate.ANIM_IDLE, false, 0, false)
		else:
			sprite.self_modulate = GameManager.GameSettings.Alpha_DeactivatedModulate


func PlayAnimation(_animString : String, _uniformTransition : bool, _animSpeed : float = 1, _fromEnd : bool = false):
	if AnimationWorkComplete:
		AnimationCTRL.play(_animString, -1, _animSpeed, _fromEnd)
		visual.speed_scale = _animSpeed


func ResetAnimation():
	AnimationCTRL.seek(0, true)

func UpdateSubmerged(_submerged : bool):
	if AnimationWorkComplete:
		pass
	else:
		if SubmergedParent != null:
			SubmergedParent.visible = _submerged

func PlayDamageAnimation(_autoReturnToIdle = true):
	if AnimationWorkComplete:
		PlayAnimation(UnitSettingsTemplate.ANIM_TAKE_DAMAGE, false, 1, false)
		visual.material.set_shader_parameter("use_color_override", true)
		visual.material.set_shader_parameter("color_override", Color.RED)

		await get_tree().create_timer(0.05).timeout

		visual.material.set_shader_parameter("use_color_override", true)
		visual.material.set_shader_parameter("color_override", Color.WHITE)

		await get_tree().create_timer(0.05).timeout

		visual.material.set_shader_parameter("use_color_override", false)


		await get_tree().create_timer(2).timeout

		if AnimationCTRL.current_animation == UnitSettingsTemplate.ANIM_TAKE_DAMAGE && _autoReturnToIdle:
			PlayAnimation(UnitSettingsTemplate.ANIM_IDLE, false, 1, false)



func SetSpeedScale(_speed : float = 1):
	AnimationCTRL.speed_scale = _speed
	if visual != null:
		visual.speed_scale = _speed

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
