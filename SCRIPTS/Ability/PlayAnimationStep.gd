extends ActionStep
class_name PlayAnimationStep

@export var AnimName : String = "idle"
@export var Speed : float = 1.0
@export var Backwards : bool = false
@export var WaitForAnimFinished : bool = false

var animComplete = false

func Enter(_actionLog : ActionLog):
	log = _actionLog
	log.source.PlayAnimation(AnimName, false, Speed, Backwards)
	if WaitForAnimFinished:
		if !log.source.visual.AnimationCTRL.has_animation(AnimName):
			animComplete = true
			return true

		animComplete = false
		log.source.visual.AnimationCTRL.animation_finished.connect(AnimFinishedCallback)
	return true

func Execute(_delta):
	if WaitForAnimFinished:
		if animComplete:
			if log.source.visual.AnimationCTRL.animation_finished.is_connected(AnimFinishedCallback):
				log.source.visual.AnimationCTRL.animation_finished.disconnect(AnimFinishedCallback)
			return true
		return false

	return true

func AnimFinishedCallback(_string : String):
	animComplete = true
