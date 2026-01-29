extends AISmartTarget
class_name AIWildNecromancer

@export var useSummon : bool = true

func StartTurn(_map : Map, _unit : UnitInstance):
	if useSummon:
		unit = _unit
		map = _map
		grid = map.grid

		# Decision Tree 1:
		# We have enough Focus to cast Raise Dead
		if Decision_RaiseDead():
			return

	super(_map, _unit)


func Decision_RaiseDead():
	# first find raise dead
	var raiseDead : Ability
	for ability in unit.Abilities:
		if ability.type == Ability.EAbilityType.Standard:
			# This should be it - otherwise we've messed up
			raiseDead = ability as Ability
			break

	if raiseDead == null || unit.currentFocus < raiseDead.focusCost:
		return false

	# If we're here we have enough focus to cast Raise Dead
	# Now we need to figure out where we're casting it
	var allTilesInRange = map.grid.GetTilesWithinRange(unit.CurrentTile.Position, raiseDead.GetRange(), false)
	for tile in allTilesInRange:
		# take the first tile that is empty
		# If range is greater than 1,1 the gettileswithinrange will be sorted from closest to furthest anyway
		if tile.Occupant == null:
			selectedTile = tile
			break

	# if for some reason the selected tile is null
	if selectedTile == null:
		return false

	# This is normally called by super, but we're not calling it if we're at this stage
	unit.QueueTurnStartDelay()

	var log = ActionLog.Construct(grid, unit, raiseDead)
	log.actionOriginTile = selectedTile
	log.affectedTiles.append(selectedTile.AsTargetData())
	unit.QueueDelayedCombatAction(log)
	return true
