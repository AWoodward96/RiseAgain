extends CombatAnimationStyleTemplate
class_name AnimStyle_SimpleSingle

@export var PreperationAnimString : String
@export var ExecutionAnimString : String
@export var Directional : bool = false

@export_category("VFX")
@export var Prep_VFX_OnSource : PackedScene
@export var Prep_VFX_OnAffectedTiles : PackedScene
@export var Enter_VFX_OnSource : PackedScene
@export var Enter_VFX_OnAffectedTiles : PackedScene
@export var Damage_VFX_OnSource : PackedScene
@export var Damage_VFX_OnAffectedTiles : PackedScene

var animationComplete : bool = false
var actionExecutionTimeout : float = 0
var animationSuffix : String = ""


func Prepare(_direction : Vector2, _source : UnitInstance, _data):
	super(_direction, _source, _data)

	animationSuffix = ""
	if Directional:
		match actionLog.actionDirection:
			GameSettingsTemplate.Direction.Up:
				animationSuffix = "_up"
			GameSettingsTemplate.Direction.Down:
				animationSuffix = "_down"
			GameSettingsTemplate.Direction.Left:
				animationSuffix = "_left"
			GameSettingsTemplate.Direction.Right:
				animationSuffix = "_right"


	if PreperationAnimString != "":
		source.PlayAnimation(PreperationAnimString + animationSuffix)

	PlayVFX_OnSource(Prep_VFX_OnSource)
	PlayVFX_OnAffectedTiles(Prep_VFX_OnAffectedTiles)
	pass

func Enter():
	if ExecutionAnimString != "":
		animationComplete = false
		source.PlayAnimation(ExecutionAnimString + animationSuffix)
		source.Visual.AnimationDealDamageCallback.connect(DamageCallback)
		source.Visual.AnimationCTRL.animation_finished.connect(AnimationCompleteCallback)
	else:
		animationComplete = true

	PlayVFX_OnSource(Enter_VFX_OnSource)
	PlayVFX_OnAffectedTiles(Enter_VFX_OnAffectedTiles)
	pass

func Execute(_delta, _direction : Vector2):
	actionExecutionTimeout += _delta

	# this is to prevent accidental softlocks
	if actionExecutionTimeout > AnimationStyleTemplate.TIMEOUT:
		return true

	return animationComplete

func DamageCallback():
	source.Visual.AnimationDealDamageCallback.disconnect(DamageCallback)
	PlayVFX_OnSource(Damage_VFX_OnSource)
	PlayVFX_OnAffectedTiles(Damage_VFX_OnAffectedTiles)
	PerformDamageCallback.emit()
	pass

func AnimationCompleteCallback(_anim_name : String):
	source.Visual.AnimationCTRL.animation_finished.disconnect(AnimationCompleteCallback)
	animationComplete = true
	pass
