extends UnitActionBase
class_name UnitDelayedCombatAction

var Log : ActionLog

func _Enter(_unit : UnitInstance, _map : Map):
	super(_unit, _map)

	_map.playercontroller.EnterActionExecutionState(Log)
