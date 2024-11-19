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

func CancelPreview():
	pass
