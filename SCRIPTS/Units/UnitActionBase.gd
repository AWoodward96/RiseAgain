class_name UnitActionBase

var unit : UnitInstance
var map : Map

var position :
	get:
		return unit.position
	set(val):
		unit.position = val

var GridPosition:
	get:
		return unit.GridPosition


func _Enter(_unit : UnitInstance, _map : Map):
	unit = _unit
	map = _map
	pass

func _Execute(_unit : UnitInstance, _delta):
	return true

func _Exit():
	pass
