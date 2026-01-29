extends CutsceneEventBase
class_name WaitEvent

@export var WaitTime : float = 1

var timer = 0

func Enter(_context : CutsceneContext):
	timer = 0
	return true

func Execute(_delta, _context : CutsceneContext):
	timer += _delta
	return timer >= WaitTime
