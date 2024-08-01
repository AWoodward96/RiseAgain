extends MapObjective
class_name UnitsKilled

@export var unitTemplate : UnitTemplate
@export var number : int = 1

func CheckObjective(_map : Map):
	if number == 0:
		return !_map.unitsKilled.has(unitTemplate)


	return _map.unitsKilled.has(unitTemplate) && _map.unitsKilled[unitTemplate] >= number
