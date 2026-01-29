extends CutsceneEventBase
class_name BlockControllerInputEvent

@export var Block : bool

func Enter(_context : CutsceneContext):
	if Map.Current != null && Map.Current.playercontroller != null:
		Map.Current.playercontroller.BlockMovementInput = Block
		return true
	return false
