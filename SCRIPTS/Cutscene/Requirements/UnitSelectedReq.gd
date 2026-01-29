extends RequirementBase
class_name UnitSelectedReq

@export var unitTemplate : UnitTemplate
@export var atSpecificCoord : bool = false
@export var specificCoord : Vector2i

func CheckRequirement(_context):
	if Map.Current == null ||  Map.Current.playercontroller == null:
		return false

	if Map.Current.playercontroller.selectedUnit == null:
		return false

	if Map.Current.playercontroller.selectedUnit.Template == unitTemplate:
		if atSpecificCoord:
			return Map.Current.playercontroller.selectedUnit.CurrentTile.Position == specificCoord
		else:
			return true

	return false
