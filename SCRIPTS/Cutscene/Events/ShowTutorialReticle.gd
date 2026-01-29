extends CutsceneEventBase
class_name ShowTutorialReticleEvent

@export var show : bool = true
@export var position : Vector2i

func Enter(_context : CutsceneContext):
	if Map.Current != null && Map.Current.playercontroller != null:
		if show:
			Map.Current.playercontroller.ShowTutorialReticle(position)
		else:
			Map.Current.playercontroller.HideTutorialReticle()
	return true
