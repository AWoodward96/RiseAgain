extends RequirementBase
class_name PartyLimitReq


@export var OpenSlots : int = 0

func CheckRequirement(_genericData):
	if GameManager.CurrentCampaign == null:
		return true

	return GameManager.CurrentCampaign.CurrentRoster.size() + OpenSlots <= GameManager.CurrentCampaign.TeamSizeLimit
