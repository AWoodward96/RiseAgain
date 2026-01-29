extends TargetingSimple
### Targeting Global Simple:
## Simple, but you can hit every unit on the map. That's it.
## You can only hit one target and this isn't shaped, so Global Shaped would need to exist but for now it's fine
class_name TargetingGlobalSimple



func GetTilesInRange(_unit : UnitInstance, _grid : Grid):
	# This is the only change that's required to make global simple work
	# Ignoring the range of the ability, just look at every unit that's on the correct team and mark it as an available tile
	# AvailableTiles when using simple targeting are only option when you get affected tiles so this is two birds with one stone
	var options : Array[Tile]
	var units : Array[UnitInstance] = []
	if TeamTargeting == ETargetingTeamFlag.AllyTeam || TeamTargeting == ETargetingTeamFlag.All:
		units.append_array(currentMap.GetUnitsOnTeam(source.UnitAllegiance))

	if TeamTargeting == ETargetingTeamFlag.EnemyTeam || TeamTargeting == ETargetingTeamFlag.All:
		if source.UnitAllegiance == GameSettingsTemplate.TeamID.ALLY || source.UnitAllegiance == GameSettingsTemplate.TeamID.NEUTRAL:
			units.append_array(currentMap.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ENEMY))
		else:
			units.append_array(currentMap.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ALLY))

	for u in units:
		# Just in case
		if u == null:
			continue

		if source.UnitAllegiance == GameSettingsTemplate.TeamID.ALLY:
			if u.ShroudedFromPlayer:
				continue


		options.append(u.CurrentTile)

	return options
