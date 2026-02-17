extends TargetingMultiSimpleBase
class_name TargetingStatScalingSimple

# could be cleaner as a single data type, but it'd be single use, so this will do fine
@export var StatScalingDefs : Array[StatDef]
@export var NumberOfTargets : Array[int]

func GetMaximumNumberOfTargets():
	if log == null || log.source == null:
		return 0

	var index = 0
	for i in range(0, StatScalingDefs.size() - 1):
		var statFloor = StatScalingDefs[i]
		var reqStat = log.source.GetWorkingStat(statFloor.Template)
		if reqStat >= statFloor.Value:
			index = i
		else:
			break

	return NumberOfTargets[index]
