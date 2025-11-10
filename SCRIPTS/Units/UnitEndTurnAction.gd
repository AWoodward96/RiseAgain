extends UnitActionBase
class_name UnitEndTurnAction

func _Enter(_unit : UnitInstance, _map : Map):
	print("Unit At: " + str(_unit.GridPosition) + " ending their turn.")
	_unit.EndTurn()

	_map.RefreshThreat()
	pass
