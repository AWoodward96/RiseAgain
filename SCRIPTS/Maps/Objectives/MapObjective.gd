extends Resource
class_name MapObjective

@export var loc_description : String

func CheckObjective(_map : Map):
	return false

func UpdateLocalization(_map : Map):
	return tr(loc_description)
