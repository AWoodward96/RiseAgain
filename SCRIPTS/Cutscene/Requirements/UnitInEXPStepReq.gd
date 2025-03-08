extends RequirementBase
class_name UnitInEXPStepReq

@export var atPosition : Vector2i

func CheckRequirement(_genericData):
	if Map.Current == null:
		return false

	var tile = Map.Current.grid.GetTile(atPosition)
	if tile != null && tile.Occupant != null:
		return tile.Occupant.CurrentAction is UnitExpGainAction

	return false
