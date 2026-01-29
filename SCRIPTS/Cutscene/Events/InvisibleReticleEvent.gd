extends CutsceneEventBase
class_name InvisibleReticleEvent

@export var Invisible : bool

func Enter(_cutsceneContext : CutsceneContext):
	CutsceneManager.local_invisible_reticle = Invisible
	return true
