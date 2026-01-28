extends MovementAnimationStyleTemplate
class_name AnimStyle_Teleport

### How long the character is invisible while teleporting
@export var invisibleTime : float = 0
@export var outAnimationString : String = ""

var inAnimationComplete : bool
var outAnimationComplete : bool
var outPlayed : bool = false
var invisibleDelta : float = 0

func Prepare(_direction : Vector2, _source : UnitInstance, _data):
	# Abridged of the AnimationStyleTemplate. A lot of the methods we've inherrited got crap in it that messes this up
	# so just reimplement them here
	source = _source
	outPlayed = false
	outAnimationComplete = false
	if _data is MovementData:
		movementData = _data

	if PreperationAnimString != "":
		inAnimationComplete = false
		source.PlayAnimation(PreperationAnimString)
		source.visual.AnimationCTRL.animation_finished.connect(InAnimationCompleteCallback)
	else:
		inAnimationComplete = true
	PlayVFX(Prep_VFX)


func Execute(_delta, _destination : Vector2):
	if inAnimationComplete:
		invisibleDelta += _delta
		if invisibleTime < invisibleDelta:
			source.visible = true
			source.position = _destination
			if !outPlayed:
				outPlayed = true
				if outAnimationString != "":
					source.PlayAnimation(outAnimationString)
					source.visual.AnimationCTRL.animation_finished.connect(OutAnimationCompleteCallback)
				else:
					outAnimationComplete = true

		else:
			source.visible = false

	return true


func InAnimationCompleteCallback(_anim_name : String):
	source.visual.AnimationCTRL.animation_finished.disconnect(InAnimationCompleteCallback)
	inAnimationComplete = true
	pass

func OutAnimationCompleteCallback(_anim_name : String):
	source.visual.AnimationCTRL.animation_finished.disconnect(OutAnimationCompleteCallback)
	outAnimationComplete = true
	pass

func Exit():
	super()
	# Just in case
	source.visible = true

func AnimationComplete():
	return outAnimationComplete
