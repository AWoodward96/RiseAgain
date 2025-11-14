extends RequirementBase
class_name UnitInParty

@export_file("*.tres") var UnitTemplateRef : String

func CheckRequirement(_genericData):
	var unitTemplate = load(UnitTemplateRef) as UnitTemplate
	if unitTemplate == null:
		return false

	if GameManager.CurrentCampaign == null:
		if Map.Current != null:
			var allyTeam = Map.Current.teams[GameSettingsTemplate.TeamID.ALLY]
			for u in allyTeam:
				if u.Template == unitTemplate:
					return true

		return false

	return GameManager.CurrentCampaign.IsUnitInRoster(unitTemplate)
