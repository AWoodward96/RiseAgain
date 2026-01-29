extends CutsceneEventBase
class_name BlockInspectUIEvent

@export var Block : bool = true

func Enter(_context : CutsceneContext):
	if Map.Current != null && Map.Current.playercontroller != null && Map.Current.playercontroller.combatHUD != null:
		Map.Current.playercontroller.combatHUD.InspectUI.GlobalDisable = Block
	return true
