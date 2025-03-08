extends RequirementBase
class_name RewardsUIOpenReq

func CheckRequirement(_context):
	return RewardsUI.Instance != null
