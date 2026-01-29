extends CutsceneEventBase
class_name BlockCancelInputEvent

@export var Block : bool

func Enter(_context : CutsceneContext):
	CutsceneManager.local_block_cancel_input = Block
	return true
