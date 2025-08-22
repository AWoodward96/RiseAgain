extends CutsceneEventBase
class_name MoveUnitEvent

@export var unitAtPosition : Vector2i
@export var route : Array[Vector2i]
@export var destination : Vector2i
@export var speed : int = 500
@export var autoEndTurn : bool = false
@export var waitForCompletion : bool = true

var unit : UnitInstance

func Enter(_context : CutsceneContext):
	if Map.Current == null:
		return false

	var tile = Map.Current.grid.GetTile(unitAtPosition)
	if tile != null && tile.Occupant != null:
		unit = tile.Occupant
		unit.MoveCharacterToNode(BuildRoute(), Map.Current.grid.GetTile(destination), null, speed, null, true)

	return true

func Execute(_delta, _context : CutsceneContext):
	if !waitForCompletion:
		return true

	if unit == null:
		return true

	if unit.IsStackFree:
		if autoEndTurn:
			unit.QueueEndTurn()
		return true
	return false

func BuildRoute():
	var tileRoute : Array[Tile] = []
	for pos in route:
		var tile = Map.Current.grid.GetTile(pos)
		if tile != null:
			tileRoute.append(tile)
	return tileRoute
