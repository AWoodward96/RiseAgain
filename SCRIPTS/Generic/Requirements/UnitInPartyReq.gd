extends RequirementBase
class_name UnitInParty

@export var UnitTemplateRef : UnitTemplate

func CheckRequirement(_genericData):
	if GameManager.CurrentCampaign == null:
		return false

	return GameManager.CurrentCampaign.IsUnitInRoster(UnitTemplateRef)
