extends RequirementBase
class_name InspectUIOpenReq

func CheckRequirement(_context):
	return UnitInspectUI.Instance != null
