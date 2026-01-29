extends RequirementBase
class_name AbilitySelectionUIOpenReq

func CheckRequirement(_context):
	return SelectAbilityUI.Instance != null
