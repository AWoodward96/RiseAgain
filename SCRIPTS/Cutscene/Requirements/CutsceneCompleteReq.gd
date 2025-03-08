extends RequirementBase
class_name CutsceneCompleteReq

@export var Cutscene : CutsceneTemplate

func CheckRequirement(_genericData):
	return PersistDataManager.universeData.completedCutscenes.has(Cutscene)
