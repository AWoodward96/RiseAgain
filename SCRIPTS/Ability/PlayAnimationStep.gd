extends ActionStep
class_name PlayAnimationStep

@export var AnimName : String = "idle"
@export var FallbackAnimName : String = "use_item_in"
@export var Speed : float = 1.0
@export var Backwards : bool = false
@export var WaitForAnimFinished : bool = false
@export var Directional : bool = false

var animComplete = false

func Enter(_actionLog : ActionLog):
	log = _actionLog

	var suffix = ""
	if Directional:
		match _actionLog.actionDirection:
			GameSettingsTemplate.Direction.Up:
				suffix = "_up"
			GameSettingsTemplate.Direction.Down:
				suffix = "_down"
			GameSettingsTemplate.Direction.Left:
				suffix = "_left"
			GameSettingsTemplate.Direction.Right:
				suffix = "_right"

	log.source.PlayAnimation(AnimName + suffix, false, Speed, Backwards)
	if WaitForAnimFinished:
		if !log.source.Visual.AnimationCTRL.has_animation(AnimName + suffix):
			animComplete = true
			return true

		animComplete = false
		log.source.Visual.AnimationCTRL.animation_finished.connect(AnimFinishedCallback)
	return true

func Execute(_delta):
	if WaitForAnimFinished:
		if animComplete:
			if log.source.Visual.AnimationCTRL.animation_finished.is_connected(AnimFinishedCallback):
				log.source.Visual.AnimationCTRL.animation_finished.disconnect(AnimFinishedCallback)
			return true
		return false

	return true

func AnimFinishedCallback(_string : String):
	animComplete = true
