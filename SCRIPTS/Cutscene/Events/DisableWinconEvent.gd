extends CutsceneEventBase
class_name DisableWinconEvent

@export var Disable : bool

func Enter(_cutsceneContext : CutsceneContext):
	CutsceneManager.local_block_wincon = Disable
	return true
