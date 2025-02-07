extends MapObjective
class_name SurviveObjective

@export var turns : int = 10

func CheckObjective(_map : Map):
	return _map.turnCount >= turns
