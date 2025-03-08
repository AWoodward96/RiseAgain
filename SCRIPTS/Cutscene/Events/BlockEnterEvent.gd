extends CutsceneEventBase
class_name BlockEnterEvent

@export var Block : bool = false

func Enter(_cutscene : CutsceneContext):
	CutsceneManager.local_block_enter_action = Block
	return true
