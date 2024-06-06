extends Resource
class_name StatDef

@export var Template : StatTemplate
@export var Value : int


func GetStat(_allOtherStats : Array[StatDef]):
	return Value
