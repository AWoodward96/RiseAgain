extends RequirementBase
class_name TeamTurnReq

@export var teamTurn : GameSettingsTemplate.TeamID

func CheckRequirement(_genericData):
	if Map.Current == null:
		return false

	return Map.Current.currentTurn == teamTurn
