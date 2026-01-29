extends CutsceneEventBase
class_name BlockObjectiveUIEvent

@export var Block : bool = true

func Enter(_context : CutsceneContext):
	if Map.Current != null && Map.Current.playercontroller != null && Map.Current.playercontroller.combatHUD != null:
		Map.Current.playercontroller.combatHUD.ObjectivePanelUI.GlobalDisable = Block
	return true
