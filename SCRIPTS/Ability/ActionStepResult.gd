extends Object
class_name ActionStepResult

var StepIndex : int = -1

var Source : UnitInstance
var Target : UnitInstance # CAN BE NULL

var TileTargetData : TileTargetedData

var ExpGain : int
var Kill : bool

func PreviewResult(_map : Map):
	pass

func Validate():
	return true

# If halfway through the execution stack we figure out that this actually isn't accurate, call Invalidate to invalidate the result
func Invalidate():
	ExpGain = 0
	Kill = false

func CancelPreview():
	pass
