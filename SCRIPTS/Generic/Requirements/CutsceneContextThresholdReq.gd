extends RequirementBase
class_name CutsceneContextThreshold

enum EContextThreshold { Above, Below, EqualTo }

@export var ContextVariableName : String
@export var Type : EContextThreshold = EContextThreshold.Above
@export var Threshold : int

func CheckRequirement(_genericData):
	if _genericData is CutsceneContext:
		if !_genericData.ContextDict.has(ContextVariableName):
			return false

		match Type:
			EContextThreshold.Above:
				return _genericData.ContextDict[ContextVariableName] > Threshold
			EContextThreshold.Below:
				return _genericData.ContextDict[ContextVariableName] < Threshold
			EContextThreshold.EqualTo:
				return _genericData.ContextDict[ContextVariableName] == Threshold

		return _genericData.ContextDict.has(ContextVariableName)
	else:
		return false
