extends CutsceneEventBase
class_name HideAllUnitsEvent

@export var Hide : bool

func Enter(_context : CutsceneContext):
	if Map.Current != null:
		if Hide:
			Map.Current.squadParent.hide()
		else:
			Map.Current.squadParent.show()
		return true
	return false
