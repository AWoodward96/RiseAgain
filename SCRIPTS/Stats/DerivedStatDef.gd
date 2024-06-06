extends StatDef
class_name DerivedStatDef

@export var ParentStat : StatTemplate
@export var Ratio : float

func GetStat(_allOtherStats : Array[StatDef]):
	var parentStat = _allOtherStats.filter(func(x) : return x.Template == ParentStat)
	if parentStat == null:
		return 0
	else:
		return Value * Ratio
