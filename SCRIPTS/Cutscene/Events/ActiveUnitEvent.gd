extends CutsceneEventBase
class_name ActivateUnitEvent

@export var unitPosition : Vector2i

func Enter(_context : CutsceneContext):
	if Map.Current != null:
		var tile = Map.Current.grid.GetTile(unitPosition)
		if tile != null && tile.Occupant != null:
			tile.Occupant.Activate(tile.Occupant.UnitAllegiance)

	return true
