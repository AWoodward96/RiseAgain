extends ActionStepResult
class_name RepeatPerFocusStepResult

var SubStepResult : Array[ActionStepResult]
var FocusAmount : int

func PreviewResult(_map : Map):
	for i in FocusAmount:
		for result in SubStepResult:
			if result != null:
				result.PreviewResult(_map)
	pass


func CancelPreview():
	for result in SubStepResult:
		if result != null:
			result.CancelPreview()
	pass
