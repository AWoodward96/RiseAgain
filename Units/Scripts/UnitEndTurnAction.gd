extends UnitActionBase
class_name UnitEndTurnAction

func _Enter(_unit : UnitInstance, _map : Map):
	_unit.EndTurn()
	pass

