extends Node2D
class_name UnitVisual

@export var AnimationCTRL : AnimationPlayer
@export var AnimationWorkComplete : bool = false
@export var SubmergedParent : Node2D
var sprite : Sprite2D
var visual : AnimatedSprite2D
var MyUnit : UnitInstance

var take_damage_step : int = 0

func _ready():
	# Sometimes visuals are used in UI's so I need an additional GetVisuals call in the Ready func so that I don't
	# need an instance to display them
	GetVisuals()

func Initialize(_unit : UnitInstance) :
	MyUnit = _unit
	GetVisuals()
	RefreshAllegience()

func GetVisuals():
	visual = get_node_or_null("Visual")
	sprite = get_node_or_null("Sprite2D")

func RefreshAllegience(_override : GameSettingsTemplate.TeamID = GameSettingsTemplate.TeamID.INVALID):
	var allegience = _override
	if allegience == GameSettingsTemplate.TeamID.INVALID && MyUnit != null:
		allegience = MyUnit.UnitAllegiance

	if visual != null:
		if AnimationWorkComplete:
			match allegience:
				GameSettingsTemplate.TeamID.ALLY:
					visual.material.set_shader_parameter("palette_index", 1)
				GameSettingsTemplate.TeamID.ENEMY:
					visual.material.set_shader_parameter("palette_index", 2)
				GameSettingsTemplate.TeamID.NEUTRAL:
					visual.material.set_shader_parameter("palette_index", 3)

		else:
			match allegience:
				GameSettingsTemplate.TeamID.ALLY:
					sprite.modulate = GameManager.GameSettings.Alpha_AlliedUnitColor
				GameSettingsTemplate.TeamID.ENEMY:
					sprite.modulate = GameManager.GameSettings.Alpha_EnemyUnitColor
				GameSettingsTemplate.TeamID.NEUTRAL:
					sprite.modulate = GameManager.GameSettings.Alpha_NeutralUnitColor
	UpdateHueSaturationValue()

func UpdateHueSaturationValue():
	if AnimationWorkComplete && Map.Current != null:
		if Map.Current.Biome != null:
			visual.material.set_shader_parameter("hue", Map.Current.Biome.UnitHue)
			visual.material.set_shader_parameter("saturation", Map.Current.Biome.UnitSaturation)
			visual.material.set_shader_parameter("value", Map.Current.Biome.UnitValue)
		else:
			visual.material.set_shader_parameter("hue", 1)
			visual.material.set_shader_parameter("saturation", 1)
			visual.material.set_shader_parameter("value", 1)

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
		if AnimationCTRL.has_animation(_animString):
			AnimationCTRL.play(_animString, -1, _animSpeed, _fromEnd)
		else:
			push_error("Unit ", MyUnit.Template.DebugName, " does not have an animation for: ", _animString)
		visual.speed_scale = _animSpeed


func ResetAnimation():
	AnimationCTRL.seek(0, true)

func UpdateSubmerged(_submerged : bool):
	if AnimationWorkComplete:
		pass
	else:
		if SubmergedParent != null:
			SubmergedParent.visible = _submerged

func UpdateShrouded():
	visible = !MyUnit.ShroudedFromPlayer
	MyUnit.uiParent.visible = !MyUnit.ShroudedFromPlayer

	if AnimationWorkComplete:
		if MyUnit.Shrouded:
			visual.material.set_shader_parameter("tint", GameManager.GameSettings.ShroudedTintModulate)
		else:
			visual.material.set_shader_parameter("tint", Color.WHITE)


func PlayAlertedFromShroudAnimation():
	visible = true
	MyUnit.uiParent.visible = true
	MyUnit.PlayAlertEmote()
	await get_tree().create_timer(1).timeout
	UpdateShrouded()


func PlayDamageAnimation(_autoReturnToIdle = true):
	if AnimationWorkComplete:
		if MyUnit.ShroudedFromPlayer:
			PlayAlertedFromShroudAnimation()

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
