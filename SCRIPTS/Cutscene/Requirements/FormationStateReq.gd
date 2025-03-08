extends RequirementBase
class_name FormationStateReq


func CheckRequirement(_genericData):
	if Map.Current == null:
		return false

	return Map.Current.MapState is PreMapState
