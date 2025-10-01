extends ActionStepResult
class_name RepeatStepResult

var SubStepResult : Array[ActionStepResult]
var RepeatAmount : int

func PreviewResult(_map : Map):
	for i in RepeatAmount:
		for result in SubStepResult:
			if result != null:
				result.PreviewResult(_map)
	pass


func CancelPreview():
	for result in SubStepResult:
		if result != null:
			result.CancelPreview()
	pass
