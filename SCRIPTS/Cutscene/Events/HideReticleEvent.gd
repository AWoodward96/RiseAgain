extends CutsceneEventBase
class_name HideReticleEvent

@export var Hide : bool = true


func Enter(_context : CutsceneContext):
	if Map.Current != null && Map.Current.playercontroller != null:
		Map.Current.playercontroller.reticle.visible = !Hide

	return true
