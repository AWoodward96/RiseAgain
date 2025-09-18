extends AIBehaviorBase
class_name AITargetClosest

# ------------AI Explanation------------
# This AI should be really dumb.
# It should only target the closet player, regardless of if they can actually damage them
# A more threatening, more interesting AI, would be SmartTargetClosest, where it'd prioritize units it could actually damage
# ---------------------------------------

@export var Flags : Array[AITargetingFlag]
@export var IsPriorityFlag : bool # If true, then Flags at index 0 take priority over Flags at 1
@export var RememberTarget : bool

var targetUnit : UnitInstance
var weapon : UnitUsable

var pathfindingOptions : Array[PathfindingOption]

func StartTurn(_map : Map, _unit : UnitInstance):
	super(_map, _unit)
	attacked = false
	selectedTile = null
	selectedPath.clear()

	var effectiveRange = unit.GetEffectiveAttackRange()
	var unitMovement = unit.GetUnitMovement()

	# STEP ZERO:
	# Check if this enemy even has an ability to use. If they don't, then there's nothing to do
	GetEquippedItem()
	if weapon == null:
		unit.QueueEndTurn()
		return

	# STEP ONE:
	# Figure out which unit we'll be targeting this turn
	# This will involve getting a path to each unit, which is necessary
	GetAllValidPaths()
	if pathfindingOptions.size() == 0:
		unit.QueueEndTurn()
		return

	# STEP TWO:
	# Now that we have all available paths to all available Units,
	# Start with the closest, and loop through to see what's the best choice
	for option in pathfindingOptions:
		targetUnit = option.Unit
		if targetUnit == null:
			continue

		# STEP THREE:
		# Now we break out. If this unit is far away, then their movement will not need to be that informed. Just move closer to the target
		# Remember, this list is sorted by distance, so if there is a closer unit to target, it would have been hit by now

		if option.PathSize > unitMovement + effectiveRange.y:
			# CASE 1:
			# The unit is too far from their target, and should simply move closer
			if !TruncatePathBasedOnMovement(option.Path, unitMovement):
				unit.QueueEndTurn()
			break # break out and go to execution
		else:
			# CASE 2:
			# We are within striking distance of our target based on the pathfinding distance and the effective range of this unit.
			var actionableTiles = GetActionableTiles()
			if actionableTiles == null || actionableTiles.size() == 0:
				unit.QueueEndTurn()
				return

			# EARLY EXIT NOTICE:
			# IF WE'RE ALREADY STANDING ON AN ACTIONABLE TILE, JUST STAY THERE, NO PATHFINDING NECESSARY
			for actionTile in actionableTiles:
				if actionTile.Occupant == unit:
					selectedTile = unit.CurrentTile
					TryCombat()
					return

			# STEP THREE:
			# Now filter down by however much movement we need to actually get to those actionable tiles
			# This method should take all actionable tiles, and return the one that is easiest to get to
			FilterTilesByPath(actionableTiles)

			# At this point we should have a valid path and a valid tile so
			if selectedTile != null && selectedPath.size() > 0:
				break
			else:
				print("First Selected Option is not good enough, going to other options")


	if selectedTile == null || selectedPath == null || selectedPath.size() == 0:
		push_error("Enemy has no selected tile, or no selected path. Ending turn by default.")
		print("Tile: ", selectedTile, " -- Path: ", selectedPath)
		unit.QueueEndTurn()
		return

	if selectedPath.size() > unitMovement:
		if !TruncatePathBasedOnMovement(selectedPath, unitMovement):
			unit.QueueEndTurn()

	# STEP FIVE:
	# MOVE
	unit.MoveCharacterToNode(selectedPath, selectedTile)

	pass

func RunTurn():
	if unit.IsStackFree && unit.Activated && !attacked:
		TryCombat()
	pass

func GetAllValidPaths():
	pathfindingOptions.clear()

	var allUnitsAbleToBeTargeted : Array[UnitInstance]

	# This parallel index is used to track FlagIndex in the PathfindingOption
	var parallelIndex : Array[int]
	var index = 0
	for targetingFlags in Flags:
		var units = map.GetUnitsOnTeam(targetingFlags.Team)
		if targetingFlags.Descriptor != null:
			units = units.filter(func(x) : return x.Template.Descriptors.find(targetingFlags.Descriptor) != -1)

		units = units.filter(func(x : UnitInstance) : return !x.Shrouded && !x.Stealthed)

		allUnitsAbleToBeTargeted.append_array(units)

		var ar : Array[int]
		ar.resize(units.size())
		ar.fill(index)
		parallelIndex.append_array(ar)

		index += 1

	for i in range(0, allUnitsAbleToBeTargeted.size()):
		var potentialUnit = allUnitsAbleToBeTargeted[i]
		var path = grid.GetPathBetweenTwoUnits(unit, potentialUnit)
		if path.size() != 0: # Check against 0, because 0 means you can't path there
			var op = PathfindingOption.new()
			path.remove_at(0) # Remove the first entry, because that is the current tile this unit is on
			op.Unit = potentialUnit
			op.Path = path
			op.FlagIndex = parallelIndex[i]

			pathfindingOptions.append(op)

	pathfindingOptions.sort_custom(SortPathfindingOptions)

func SortPathfindingOptions(path1 : PathfindingOption, path2 : PathfindingOption):
	if IsPriorityFlag:
		if path1.FlagIndex != path2.FlagIndex:
			return path1.FlagIndex < path2.FlagIndex

	return path1.PathSize < path2.PathSize

func GetActionableTiles():
	var tilesWithinRange = grid.GetTilesWithinRange(targetUnit.GridPosition, weapon.GetRange())
	tilesWithinRange = tilesWithinRange.filter(func(tile) : return tile.Occupant == null || (tile.Occupant == unit))
	tilesWithinRange = tilesWithinRange.filter(func(tile) : return !tile.IsWall)
	return tilesWithinRange

func FilterTilesByPath(_actionableTiles : Array[Tile]):
	var lowest = 1000000
	for tile in _actionableTiles:
		var path = grid.GetTilePath(unit, unit.CurrentTile, tile, true, false, false)
		if path.size() < lowest && path.size() != 0: # Check 0 path size, because that indicates that there is no path to that tile
			selectedTile = tile
			selectedPath = path
			selectedPath.remove_at(0) # Remove the first entry, because that is the current tile this unit is on
			lowest = path.size()

func GetEquippedItem():
	weapon = unit.EquippedWeapon

func TryCombat():
	attacked = true
	if targetUnit == null:
		unit.QueueEndTurn()
		return

	if !weapon.IsWithinRange(selectedTile.Position, targetUnit.GridPosition):
		unit.QueueEndTurn()
		return

	## default to the first ability
	if weapon != null && weapon.UsableDamageData != null:
		var log = ActionLog.Construct(map.grid, unit, weapon)
		log.actionOriginTile = targetUnit.CurrentTile # This is the target we're attacking, so the origin is here
		log.sourceTile = selectedTile	# Remember, we're pathfinding to this tile so the source has to be from here
		log.affectedTiles.append(targetUnit.CurrentTile.AsTargetData())
		log.damageData = weapon.UsableDamageData

		# The unit still needs to get to their destination first, so queue it up as a sequence
		unit.QueueDelayedCombatAction(log)
	else:
		push_error("Unit is attempting to TryCombat with TargetClosest AI, without an Item that does damage")
