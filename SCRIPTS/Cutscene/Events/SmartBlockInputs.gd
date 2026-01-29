extends CutsceneEventBase
class_name SmartBlockInputs

@export var BlockMovementInput : bool = false
@export var BlockSelectInput : bool = false
@export var BlockCancelInput : bool = false
@export var BlockInspectInput : bool = false

func Enter(_context : CutsceneContext):
	CutsceneManager.local_block_movement_input = BlockMovementInput
	CutsceneManager.local_block_select_input = BlockSelectInput
	CutsceneManager.local_block_cancel_input = BlockCancelInput
	CutsceneManager.local_block_inspect_input = BlockInspectInput
	return true
