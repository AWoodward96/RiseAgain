extends CutsceneEventBase
class_name ShowTutorialPromptEvent

@export var show : bool = true
@export var loc_text : String

func Enter(_context : CutsceneContext):
	if Map.Current != null && Map.Current.playercontroller != null && Map.Current.playercontroller.combatHUD != null:
		if show:
			Map.Current.playercontroller.combatHUD.ShowTutorialPrompt(loc_text)
		else:
			Map.Current.playercontroller.combatHUD.HideTutorialPrompt()
		return true
	return false
