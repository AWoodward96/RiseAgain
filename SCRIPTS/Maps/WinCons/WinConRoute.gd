extends MapWinCondition
class_name WinConRoute

func CheckWincon(_map : Map):
	var enemies = _map.GetUnitsOnTeam(GameSettings.TeamID.ENEMY)
	if enemies.size() == 0:
		return true

	return false
