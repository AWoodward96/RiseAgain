extends MapObjective
class_name DefeatBossObjective


func CheckObjective(_map : Map):
	for unit in _map.teams[GameManager.GameSettings.TeamID.ENEMY]:
		if unit == null:
			continue

		if unit.IsBoss:
			return false

	return true
