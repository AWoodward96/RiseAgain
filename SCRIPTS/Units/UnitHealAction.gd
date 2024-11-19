extends UnitActionBase
class_name UnitHealAction

var delay
var Log : ActionLog
var ActionIndex : int
var targetUnits : Array[UnitInstance]

func _Enter(_unit : UnitInstance, _map : Map):
	super(_unit, _map)

	delay = false
	await _map.get_tree().create_timer(Juice.combatSequenceWarmupTimer).timeout

	var actions = Log.GetResultsFromActionIndex(ActionIndex)
	for results in actions:
		results.Target.DoHeal(results)

	await _map.get_tree().create_timer(Juice.combatSequenceCooloffTimer).timeout
	delay = true
	pass

func _Execute(_unit : UnitInstance, _delta):
	return delay
