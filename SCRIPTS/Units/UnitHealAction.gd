extends UnitActionBase
class_name UnitHealAction

var delay
var healData : HealComponent
var targetUnits : Array[UnitInstance]

func _Enter(_unit : UnitInstance, _map : Map):
	super(_unit, _map)

	delay = false
	await _map.get_tree().create_timer(Juice.combatSequenceWarmupTimer).timeout

	for units in targetUnits:
		units.DoHeal(healData, _unit)

	await _map.get_tree().create_timer(Juice.combatSequenceCooloffTimer).timeout
	delay = true
	pass

func _Execute(_unit : UnitInstance, _delta):
	return delay
