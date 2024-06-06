extends UnitActionBase
class_name UnitDelayAction

var delay

func _Enter(_unit : UnitInstance, _map : Map):
	super(_unit, _map)

	delay = false
	await _map.get_tree().create_timer(Juice.enemyTurnWarmup).timeout
	delay = true
	pass

func _Execute(_unit : UnitInstance, _delta):
	return delay
