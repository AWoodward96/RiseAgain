extends MapObjective
class_name UnitsLeftAlive

@export var targetingFlag : AITargetingFlag
@export var number : int = 1

func CheckObjective(_map : Map):
	var count = 0

	var allUnitsOnTeam = _map.GetUnitsOnTeam(targetingFlag.Team)
	if targetingFlag.Descriptor != null:
		allUnitsOnTeam = allUnitsOnTeam.filter(func(x) : return x.Template.Descriptors.find(targetingFlag.Descriptor) != -1)

	for unit in allUnitsOnTeam:
		if unit == null:
			continue
		count += 1

	if number == 0:
		return count == 0

	return count >= number
