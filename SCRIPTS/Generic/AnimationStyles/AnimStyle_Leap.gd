extends MovementAnimationStyleTemplate
class_name AnimStyle_Leap

var leapTimer = 0
var jumpStart : Vector2
var travelVector : Vector2

func Prepare(_direction : Vector2, _source : UnitInstance, _data):
	super(_direction, _source, _data)

	travelVector = _direction # This is specific to the UnitMoveAction - so watch out there
	leapTimer = 0
	jumpStart = source.position
	source.leapSound.play()


func Execute(_delta, _destination : Vector2):
	var distanceTo = source.position.distance_squared_to(_destination)

	if leapTimer <= 1:
		var height = sin(PI * leapTimer) * (jumpStart.distance_to(_destination) * 0.3)
		source.position = jumpStart.lerp(_destination, leapTimer) - Vector2(0, height)
		leapTimer += _delta / 1
	else:
		source.landSound.play()
		source.position = _destination

	if distanceTo > (travelVector.length_squared() / 2):
		if travelVector.y < 0:
			source.PlayAnimation(UnitSettingsTemplate.ANIM_JUMP_BACK_UP)
		else:
			source.PlayAnimation(UnitSettingsTemplate.ANIM_JUMP_FRONT_UP)
	else:
		if travelVector.y < 0:
			source.PlayAnimation(UnitSettingsTemplate.ANIM_JUMP_BACK_DOWN)
		else:
			source.PlayAnimation(UnitSettingsTemplate.ANIM_JUMP_FRONT_DOWN)

	if source.visual.AnimationWorkComplete:
		source.visual.visual.flip_h = travelVector.x < 0

func Exit():
	if source != null && source.visual.AnimationWorkComplete:
		source.visual.visual.flip_h = false
