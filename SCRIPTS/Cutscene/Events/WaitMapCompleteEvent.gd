extends CutsceneEventBase
class_name WaitMapCompleteEvent

func Enter(_context : CutsceneContext):
	if Map.Current != null:
		return Map.Current.MapState is VictoryState

	return false
