extends CutsceneEventBase
class_name QueueCutsceneEvent

@export var Cutscene : CutsceneTemplate

func Enter(_context : CutsceneContext):
	CutsceneManager.QueueCutscene(Cutscene)
	return true
