extends CutsceneEventBase
class_name BlockRewardSelection

@export var Block : bool = false


func Enter(_cutscene : CutsceneContext):
	CutsceneManager.local_block_reward_selection = Block
	return true
