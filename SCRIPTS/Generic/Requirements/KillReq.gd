extends RequirementBase
class_name KillReq


func CheckRequirement(_actionLog : ActionLog):
	for results in _actionLog.actionResults:
		if results.Kill:
			return true

	return false
