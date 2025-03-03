extends CutsceneEventBase
class_name BlockAllInputEvent

@export var Block : bool = true

func Enter(_context : CutsceneContext):
	CutsceneManager.local_block_all_input = Block
	return true
