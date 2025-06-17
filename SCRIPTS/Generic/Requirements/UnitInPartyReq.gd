extends RequirementBase
class_name UnitInParty

@export var UnitTemplateRef : UnitTemplate

func CheckRequirement(_genericData):
	if GameManager.CurrentCampaign == null:
		if Map.Current != null:
			var allyTeam = Map.Current.teams[GameSettingsTemplate.TeamID.ALLY]
			for u in allyTeam:
				if u.Template == UnitTemplateRef:
					return true

		return false

	return GameManager.CurrentCampaign.IsUnitInRoster(UnitTemplateRef)
