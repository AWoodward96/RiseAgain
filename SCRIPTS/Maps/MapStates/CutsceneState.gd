extends MapStateBase
class_name CutsceneState


func Enter(_map : Map, _ctrl : PlayerController):
	super(_map,_ctrl)

	controller.EnterCutsceneState()

func ToJSON():
	return "CutsceneState"
