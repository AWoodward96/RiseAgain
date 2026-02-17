extends Node2D
class_name UnitVisual

signal AnimationDealDamageCallback

@export var AnimationCTRL : AnimationPlayer
@export var AnimationWorkComplete : bool = false
@export var SubmergedParent : Node2D
@export var SubmergedAnimationCTRL : AnimationPlayer

var sprite : Sprite2D
var visual : AnimatedSprite2D
var submergedVisual : AnimatedSprite2D
var myUnit : UnitInstance
var submerged : bool = false

var greyscale_base : float = 0
var take_damage_step : int = 0
var envPointLight : Node2D

func _ready():
	# Sometimes visuals are used in UI's so I need an additional GetVisuals call in the Ready func so that I don't
	# need an instance to display them
	GetVisuals()
	if visual != null && AnimationWorkComplete:
		greyscale_base = visual.material.get_shader_parameter("grey_scale_offset")

func Initialize(_unit : UnitInstance) :
	myUnit = _unit
	GetVisuals()
	RefreshAllegience()
	RefreshFlying()

func GetVisuals():
	visual = get_node_or_null("Visual")
	sprite = get_node_or_null("Sprite2D")
	submergedVisual = get_node_or_null("SubmergedParent/SubmergedVisual")

	if visual != null:
		visual.y_sort_enabled = true
	if sprite != null:
		sprite.y_sort_enabled = true
	if submergedVisual != null:
		submergedVisual.y_sort_enabled = true
	y_sort_enabled = true

func RefreshAllegience(_override : GameSettingsTemplate.TeamID = GameSettingsTemplate.TeamID.INVALID):
	var allegience = _override
	if allegience == GameSettingsTemplate.TeamID.INVALID && myUnit != null:
		allegience = myUnit.UnitAllegiance

	if AnimationWorkComplete && visual != null:
		var index : int = 0
		match allegience:
			GameSettingsTemplate.TeamID.ALLY:
				index = 1
			GameSettingsTemplate.TeamID.ENEMY:
				index = 2
			GameSettingsTemplate.TeamID.NEUTRAL:
				index = 3

		visual.material.set_shader_parameter("palette_index", index)
		if submergedVisual != null:
			submergedVisual.material.set_shader_parameter("palette_index", index)
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
	if Map.Current != null:
		if AnimationWorkComplete:
			if Map.Current.Biome != null:
				visual.material.set_shader_parameter("hue", Map.Current.Biome.UnitHue)
				visual.material.set_shader_parameter("saturation", Map.Current.Biome.UnitSaturation)
				visual.material.set_shader_parameter("value", Map.Current.Biome.UnitValue)
				visual.material.set_shader_parameter("grey_scale_offset", greyscale_base + Map.Current.Biome.GrayscaleUnitOffset)
				if submergedVisual != null:
					submergedVisual.material.set_shader_parameter("hue", Map.Current.Biome.UnitHue)
					submergedVisual.material.set_shader_parameter("saturation", Map.Current.Biome.UnitSaturation)
					submergedVisual.material.set_shader_parameter("value", Map.Current.Biome.UnitValue)
					submergedVisual.material.set_shader_parameter("grey_scale_offset", greyscale_base + Map.Current.Biome.GrayscaleUnitOffset)

			else:
				visual.material.set_shader_parameter("hue", 1)
				visual.material.set_shader_parameter("saturation", 1)
				visual.material.set_shader_parameter("value", 1)

		if Map.Current.Biome != null:
			if envPointLight != null:
				envPointLight.queue_free()

			if Map.Current.Biome.UnitLight != null:
				envPointLight = Map.Current.Biome.UnitLight.instantiate()
				add_child(envPointLight)


func SetActivated(_activated : bool):
	if AnimationWorkComplete:
		visual.material.set_shader_parameter("grey_scale", !_activated)
		if submergedVisual != null:
			submergedVisual.material.set_shader_parameter("grey_scale", !_activated)
	else:
		if _activated:
			sprite.self_modulate = Color.WHITE
			myUnit.TryPlayIdleAnimation()
		else:
			sprite.self_modulate = GameManager.GameSettings.Alpha_DeactivatedModulate


func PlayAnimation(_animString : String, _uniformTransition : bool, _animSpeed : float = 1, _fromEnd : bool = false):
	if AnimationWorkComplete:
		if submerged && SubmergedAnimationCTRL != null:
			SubmergedAnimationCTRL.play(_animString, -1, _animSpeed, _fromEnd)
		elif AnimationCTRL.has_animation(_animString):
			AnimationCTRL.play(_animString, -1, _animSpeed, _fromEnd)
		else:
			push_error("Unit ", myUnit.Template.DebugName, " does not have an animation for: ", _animString)
		visual.speed_scale = _animSpeed


func ResetAnimation():
	AnimationCTRL.seek(0, true)

func UpdateSubmerged(_submerged : bool):
	if !_submerged && submerged:
		if Map.Current != null:
			var vfx = Juice.SplashVFX.instantiate()
			vfx.global_position = global_position
			Map.Current.add_child(vfx)


	submerged = _submerged
	if AnimationWorkComplete:
		if SubmergedParent != null:
			SubmergedParent.visible = submerged

		if visual != null:
			visual.visible = !submerged
	else:
		if SubmergedParent != null:
			SubmergedParent.visible = submerged



func RefreshFlying():
	if AnimationWorkComplete:
		visual.z_index = 1 if myUnit.IsFlying else 0
	else:
		sprite.z_index = 1 if myUnit.IsFlying else 0

func UpdateShrouded():
	visible = !myUnit.ShroudedFromPlayer

	myUnit.damageIndicator.visible = !myUnit.ShroudedFromPlayer

	if AnimationWorkComplete:
		if myUnit.Shrouded:
			visual.material.set_shader_parameter("tint", GameManager.GameSettings.ShroudedTintModulate)
		else:
			visual.material.set_shader_parameter("tint", Color.WHITE)


func PlayAlertedFromShroudAnimation():
	visible = true

	myUnit.PlayAlertEmote()
	await get_tree().create_timer(1).timeout
	UpdateShrouded()

func AnimationDealDamage():
	AnimationDealDamageCallback.emit()

func PlayDamageAnimation(_autoReturnToIdle = true):
	if AnimationWorkComplete:
		var visualToEdit = visual
		if submerged && submergedVisual != null:
			visualToEdit = submergedVisual

		if myUnit.ShroudedFromPlayer:
			PlayAlertedFromShroudAnimation()

		if !myUnit.UsingSlowSpeedAbility:
			PlayAnimation(UnitSettingsTemplate.ANIM_TAKE_DAMAGE, false, 1, false)

		visualToEdit.material.set_shader_parameter("use_color_override", true)
		visualToEdit.material.set_shader_parameter("color_override", Color.RED)

		await get_tree().create_timer(0.05).timeout

		visualToEdit.material.set_shader_parameter("use_color_override", true)
		visualToEdit.material.set_shader_parameter("color_override", Color.WHITE)

		await get_tree().create_timer(0.05).timeout

		visualToEdit.material.set_shader_parameter("use_color_override", false)


		await get_tree().create_timer(2).timeout

		if AnimationCTRL.current_animation == UnitSettingsTemplate.ANIM_TAKE_DAMAGE && _autoReturnToIdle && !myUnit.UsingSlowSpeedAbility:
			PlayAnimation(UnitSettingsTemplate.ANIM_IDLE, false, 1, false)

func PlayMissAnimation(_autoReturnToIdle = true):
	if AnimationWorkComplete:
		await get_tree().create_timer(2).timeout

		if _autoReturnToIdle && !myUnit.UsingSlowSpeedAbility:
			PlayAnimation(UnitSettingsTemplate.ANIM_IDLE, false, 1, false)

func SetSpeedScale(_speed : float = 1):
	AnimationCTRL.speed_scale = _speed
	if visual != null:
		visual.speed_scale = _speed

func GetAnimString(_suffix : String):
	var animStr = ""
	match(myUnit.UnitAllegiance):
		GameSettingsTemplate.TeamID.ALLY:
			animStr = "Ally"
		GameSettingsTemplate.TeamID.ENEMY:
			animStr = "Enemy"
		GameSettingsTemplate.TeamID.NEUTRAL:
			animStr = "Neutral"

	return "Unit" + animStr + "Library/" + _suffix
