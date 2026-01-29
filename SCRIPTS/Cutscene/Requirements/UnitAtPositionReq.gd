extends RequirementBase
class_name UnitAtPositionReq

@export var unitTemplate : UnitTemplate
@export var position : Vector2i

func CheckRequirement(_genericData):
	if Map.Current != null:
		var tile = Map.Current.grid.GetTile(position)
		return tile.Occupant != null && tile.Occupant.Template == unitTemplate
	return false
