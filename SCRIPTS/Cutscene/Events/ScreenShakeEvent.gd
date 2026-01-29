extends CutsceneEventBase
class_name ScreenShakeEvent

@export var Strength : int = 8
@export var Duration : float = 0.5
@export var WaitTillComplete : bool = false
var dt : float = 0

func Enter(_context : CutsceneContext):
	if Map.Current != null:
		Map.Current.playercontroller.StartScreenShake(Strength, Duration)
	dt = 0
	return true


func Execute(_delta : float, _context : CutsceneContext):
	if !WaitTillComplete:
		return true

	dt += _delta
	return dt >= Duration
