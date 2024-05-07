extends UnitActionBase
class_name UnitDefendAction

var SourcePosition : Vector2

func _Enter(_unit : UnitInstance, _map : Map):
	super(_unit, _map)
	var dst = (position - SourcePosition).normalized()
	dst = dst * (Juice.combatSequenceDefenseOffset * map.TileSize)
	position += dst

func _Execute(_unit : UnitInstance, delta):
	# We should be off center now, move back towards your grid position
	var desired = _unit.GridPosition * map.TileSize
	position = lerp(position, (GridPosition * map.TileSize) as Vector2, Juice.combatSequenceReturnToOriginLerp * delta)
	if position.distance_squared_to(desired) < (Juice.combatSequenceReturnToOriginLerp * Juice.combatSequenceReturnToOriginLerp):
		position = desired
		return true
	return false
