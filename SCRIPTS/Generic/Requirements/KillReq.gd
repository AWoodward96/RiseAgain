extends RequirementBase
class_name KillReq


# Generic should be an action log here
func CheckRequirement(_genericData):
	if _genericData is not ActionLog:
		return false

	var actionLog = _genericData as ActionLog
	for results in actionLog.actionStepResults:
		if results.Kill:
			return true

	return false
