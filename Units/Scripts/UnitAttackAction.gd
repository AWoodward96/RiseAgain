extends UnitActionBase
class_name UnitAttackAction

var TargetPosition : Vector2

func _Enter(_unit : UnitInstance, _map : Map):
	super(_unit, _map)
	var dst = (TargetPosition - _unit.position).normalized()
	dst = dst * (Juice.combatSequenceAttackOffset * map.TileSize)
	_unit.position += dst

func _Execute(_unit : UnitInstance, delta):
	# We should be off center now, move back towards your grid position
	var desired = _unit.GridPosition * map.TileSize
	position = lerp(position, (GridPosition * map.TileSize) as Vector2, Juice.combatSequenceReturnToOriginLerp * delta)
	if position.distance_squared_to(desired) < (Juice.combatSequenceReturnToOriginLerp * Juice.combatSequenceReturnToOriginLerp):
		position = desired
		return true
	return false
