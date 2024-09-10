extends MapObjective
class_name RouteObjective

func CheckObjective(_map : Map):
	var enemies = _map.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ENEMY)
	if enemies.size() == 0:
		return true

	return false
