extends CutsceneEventBase
class_name FocusReticleEvent

@export var Position : Vector2i

func Enter(_context : CutsceneContext):
	if Map.Current != null && Map.Current.playercontroller != null:
		Map.Current.playercontroller.ForceReticlePosition(Position)
		return true
	return false
