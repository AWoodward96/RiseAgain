extends MapOption
class_name WeightedMapOption

@export var map : PackedScene
@export var weight : int = 1

# Will be used when rolling
var accumulatedWeight : int = 1

func GetMap():
	return map
