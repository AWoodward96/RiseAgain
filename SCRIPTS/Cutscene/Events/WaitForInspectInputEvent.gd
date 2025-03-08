extends CutsceneEventBase
class_name WaitForInspectInput

var actionComplete : bool = false

func Enter(_cutsceneContext : CutsceneContext):
	actionComplete = false
	return true

func Execute(_delta, _cutsceneContext : CutsceneContext):
	if InputManager.infoDown:
		return true

	return false
