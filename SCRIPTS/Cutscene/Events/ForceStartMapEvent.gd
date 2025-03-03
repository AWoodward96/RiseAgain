extends CutsceneEventBase
class_name ForceStartMapEvent

@export var GoToCutsceneState : bool = false

func Enter(_cutsceneContext : CutsceneContext):
	var map = Map.Current
	if map == null:
		return false

	if GoToCutsceneState:
		map.ChangeMapState(CutsceneState.new())
	else:
		map.ChangeMapState(CombatState.new())
	return true
