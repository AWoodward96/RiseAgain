extends ActionStepResult
class_name PushStepResult

func PreviewResult(_map : Map):
	if TileTargetData == null:
		return

	for stack in TileTargetData.pushStack:
		pass
	pass

func CancelPreview():
	pass
