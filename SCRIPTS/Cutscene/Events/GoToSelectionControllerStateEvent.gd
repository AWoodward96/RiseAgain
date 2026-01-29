extends CutsceneEventBase
class_name GoToSelectionControllerStateEvent

func Enter(_context : CutsceneContext):
	if Map.Current != null && Map.Current.playercontroller != null:
		Map.Current.playercontroller.ChangeControllerState(SelectionControllerState.new(), null)
	return true
