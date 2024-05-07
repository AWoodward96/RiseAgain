extends AIBehaviorBase
class_name AIEndTurn

func StartTurn(_map : Map, _unit : UnitInstance):
	_unit.QueueEndTurn()
	pass
