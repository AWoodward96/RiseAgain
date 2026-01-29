extends CutsceneEventBase
class_name BlockAllInputEvent

@export var Block : bool = true

func Enter(_context : CutsceneContext):
	CutsceneManager.local_block_movement_input = Block
	return true
