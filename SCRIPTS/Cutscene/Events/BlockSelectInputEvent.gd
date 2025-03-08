extends CutsceneEventBase
class_name BlockSelectInputEvent

@export var Block : bool

func Enter(_context : CutsceneContext):
	CutsceneManager.local_block_select_input = Block
	return true
