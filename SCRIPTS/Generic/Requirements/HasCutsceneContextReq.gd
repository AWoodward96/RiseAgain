extends RequirementBase
class_name HasCutsceneContextReq

@export var ContextVariableName : String

func CheckRequirement(_genericData):
	if _genericData is CutsceneContext:
		return _genericData.ContextDict.has(ContextVariableName)
	else:
		return false
