extends MapObjective
class_name UnitsKilled

@export var unitTemplate : UnitTemplate
@export var number : int = 1

func CheckObjective(_map : Map):
	if number == 0:
		return !_map.enemyUnitsKilled.has(unitTemplate)

	return GetUnitsKilled(_map) >= number

func GetUnitsKilled(_map : Map):
	if unitTemplate != null:
		if !_map.enemyUnitsKilled.has(unitTemplate):
			return 0
		return _map.enemyUnitsKilled[unitTemplate]

	var totalCount = 0
	for pair in _map.enemyUnitsKilled:
		totalCount += _map.enemyUnitsKilled[pair]
	return totalCount

func UpdateLocalization(_map : Map):
	var returnString = tr(loc_description)
	var madlibs = {}
	madlibs["CUR"] = str(GetUnitsKilled(_map))
	madlibs["MAX"] = str(number)
	return returnString.format(madlibs)
