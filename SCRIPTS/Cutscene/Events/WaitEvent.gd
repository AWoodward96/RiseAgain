extends CutsceneEventBase
class_name WaitEvent

@export var WaitTime : float = 1

var delta = 0

func Enter(_context : CutsceneContext):
	delta = 0
	return true

func Execute(_delta, _context : CutsceneContext):
	delta += _delta
	return delta >= WaitTime
