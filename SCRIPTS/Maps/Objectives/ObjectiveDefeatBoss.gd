extends MapObjective
class_name DefeatBossObjective


func CheckObjective(_map : Map):
	if _map.teams.has(GameManager.GameSettings.TeamID.ENEMY):
		for unit in _map.teams[GameManager.GameSettings.TeamID.ENEMY]:
			if unit == null:
				continue

			if unit.IsBoss:
				return false

	return true
