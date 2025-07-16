extends RequirementBase
class_name StatCheckReq

@export var StatCheck : StatDef

func CheckRequirement(_genericData):
	if GameManager.CurrentCampaign != null:
		for u in GameManager.CurrentCampaign.CurrentRoster:
			var check = u.GetWorkingStat(StatCheck.Template)
			if check >= StatCheck.Value:
				return true
	elif Map.Current != null:
		var team = Map.Current.teams[GameSettingsTemplate.TeamID.ALLY]
		for u in team:
			var check = u.GetWorkingStat(StatCheck.Template)
			if check >= StatCheck.Value:
				return true

	return false
