extends CutsceneEventBase
class_name MarkEventMapComplete

func Enter(_context : CutsceneContext):
	if Map.Current != null:
		Map.Current.EventComplete = true
		Map.Current.ChangeMapState(VictoryState.new())
		return true
	return false
