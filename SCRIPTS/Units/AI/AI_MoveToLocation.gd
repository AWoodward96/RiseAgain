extends AIBehaviorBase
class_name AIMoveToLocation

@export var positionToMoveTo : Vector2i

func StartTurn(_map : Map, _unit : UnitInstance):
	super(_map, _unit)

	if unit.GridPosition == positionToMoveTo:
		map.RemoveUnitFromMap(unit)
		return

	var workingPath = map.grid.Pathfinding.get_point_path(unit.GridPosition, positionToMoveTo)
	workingPath.remove_at(0) # index 0 is the units current position

	if !TruncatePathBasedOnMovement(workingPath, unit.GetUnitMovement()):
		unit.QueueEndTurn()
		return

	unit.MoveCharacterToNode(selectedPath, selectedTile)
	unit.QueueEndTurn()

func RunTurn():
	pass
