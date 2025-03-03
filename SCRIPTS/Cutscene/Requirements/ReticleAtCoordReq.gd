extends RequirementBase
class_name ReticleAtCoordReq

@export var Coord : Vector2i

func CheckRequirement(_context):
	if Map.Current == null ||  Map.Current.playercontroller == null:
		return false

	if Map.Current.playercontroller.CurrentTile.Position == Coord:
		return true

	return false
