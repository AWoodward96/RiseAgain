extends MapObjective
class_name GameOverObjective


func CheckObjective(_map : Map):
	var unitsAliveOnAllied = _map.GetUnitsOnTeam(GameManager.GameSettings.TeamID.ALLY)
	for u in unitsAliveOnAllied:
		if u == null:
			continue

		if u.currentHealth > 0:
			return false

	return true
