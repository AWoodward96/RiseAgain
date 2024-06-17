class_name PathfindingOption

var Unit : UnitInstance

var Path : PackedVector2Array
var PathSize :
	get:
		if Path == null:
			return 0

		return Path.size()

var FlagIndex : int
