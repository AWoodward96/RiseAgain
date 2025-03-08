extends CutsceneEventBase
class_name FreezeAndWaitForInput

@export var minimumFreezeTime : float = 0

var frozen : bool = false
var frozenTime : float = 0

func Enter(_context : CutsceneContext):
	frozen = true
	frozenTime = 0
	GameManager.get_tree().paused = true
	return true

func Execute(_delta, _context : CutsceneContext):
	frozenTime += _delta

	if minimumFreezeTime > 0:
		if frozenTime > minimumFreezeTime:
			if Input.is_anything_pressed():
				frozen = false
			return !frozen
		else:
			return false
	else:
		if Input.is_anything_pressed():
			frozen = false
		return !frozen

func Exit(_context : CutsceneContext):
	GameManager.get_tree().paused = false
