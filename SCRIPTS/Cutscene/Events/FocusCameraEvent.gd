extends CutsceneEventBase
class_name FocusCameraEvent

@export var Position : Vector2i
@export var Instantaneous : bool
@export var BuiltInWaitTime : float = 0

var delta : float = 0

func Enter(_context : CutsceneContext):
	if Map.Current != null && Map.Current.playercontroller != null:
		Map.Current.playercontroller.ForceCameraPosition(Position, Instantaneous)
		delta = 0
		return true
	return false

func Execute(_delta, _context : CutsceneContext):
	delta += _delta
	return delta >= BuiltInWaitTime
