extends CutsceneEventBase
class_name BasicMovementKeystrokeListenerEvent

var left : bool = false
var right : bool = false
var up : bool = false
var down : bool = false

func Enter(_context : CutsceneContext):
	left = false
	right = false
	up = false
	down = false
	return true

func Execute(_delta, _context : CutsceneContext):
	if InputManager.inputDown[0]:
		up = true
	if InputManager.inputDown[1]:
		right = true
	if InputManager.inputDown[2]:
		down = true
	if InputManager.inputDown[3]:
		left = true

	return up && right && down && left
