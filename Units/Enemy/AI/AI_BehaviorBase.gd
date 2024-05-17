extends Resource
class_name AIBehaviorBase

var map : Map
var unit : UnitInstance

func StartTurn(_map : Map, _unit : UnitInstance):
	unit = _unit
	map = _map

	unit.QueueTurnStartDelay()
	pass

func RunTurn():
	pass
