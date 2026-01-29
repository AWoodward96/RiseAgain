extends CutsceneEventBase
class_name ForceEndCutsceneEvent

func Enter(_context : CutsceneContext):
	if CutsceneManager.active_cutscene != null:
		CutsceneManager.active_cutscene.forceComplete = true
	# Block the execution from continuing further
	return false
