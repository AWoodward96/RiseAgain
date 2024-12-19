extends AggroRange
class_name DelayedAggro

@export var TurnsToAggro : int = 3


func Check(_self : UnitInstance, _map : Map) -> bool:
	if !_self.has_meta("TurnsToAggro"):
		_self.set_meta("TurnsToAggro", TurnsToAggro)

	var metaTurn = _self.get_meta("TurnsToAggro")
	if metaTurn <= 0:
		return true
	else:
		_self.set_meta("TurnsToAggro", metaTurn - 1)

	return super(_self, _map)
