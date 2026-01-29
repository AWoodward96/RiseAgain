extends MapObjective
class_name SurviveObjective

@export var turns : int = 10

func CheckObjective(_map : Map):
	return _map.turnCount >= turns

func UpdateLocalization(_map : Map):
	var returnString = tr(loc_description)
	var madlibs = {}
	madlibs["CUR"] = str(_map.turnCount)
	madlibs["MAX"] = str(turns)
	return returnString.format(madlibs)
