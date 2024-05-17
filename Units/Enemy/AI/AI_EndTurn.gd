extends AIBehaviorBase
class_name AIEndTurn

func StartTurn(_map : Map, _unit : UnitInstance):
	super(_map, _unit)
	_unit.QueueEndTurn()
	pass
