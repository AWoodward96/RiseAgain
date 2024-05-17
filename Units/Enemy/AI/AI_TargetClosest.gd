extends AIBehaviorBase
class_name AITargetClosest

# ------------AI Explanation------------
# This AI should be really dumb.
# It should only target the closet player, regardless of if they can actually damage them
# A more threatening, more interesting AI, would be SmartTargetClosest, where it'd prioritize units it could actually damage
# ---------------------------------------

@export_flags("ALLY", "ENEMY", "NEUTRAL") var TargetingFlags : int = 0
@export var RememberTarget : bool

var targetUnit : UnitInstance


var grid : Grid
var pathfinding  : AStarGrid2D
var selectedTile : Tile
var selectedPath : PackedVector2Array

var ability : AbilityInstance

var pathfindingOptions : Array[PathfindingOption]

func StartTurn(_map : Map, _unit : UnitInstance):
	super(_map, _unit)
	grid = _map.grid
	pathfinding = map.grid.Pathfinding

	selectedTile = null
	selectedPath.clear()

	# STEP ZERO:
	# Check if this enemy even has an ability to use. If they don't, then there's nothing to do
	GetAbility()
	if ability == null:
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
		var unitMovement = unit.GetUnitMovement()
		var effectiveRange = unit.GetEffectiveAttackRange()
		if option.PathSize > unitMovement + effectiveRange.y:
			# CASE 1:
			# The unit is too far from their target, and should simply move closer
			selectedPath = option.Path
			TruncatePathBasedOnMovement(unitMovement)
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


	if selectedTile == null || selectedPath == null || selectedPath.size() ==0:
		push_error("Enemy has no selected tile, or no selected path. Ending turn by default.")
		print("Tile: ", selectedTile, " -- Path: ", selectedPath)
		unit.QueueEndTurn()
		return

	# STEP FIVE:
	# MOVE
	unit.MoveCharacterToNode(selectedPath, selectedTile)
	TryCombat()
	pass

# Needs SelectedPath to be set before calling
func TruncatePathBasedOnMovement(currentMovement):
	selectedPath = selectedPath.slice(0, currentMovement)

	var indexedSize = selectedPath.size() - 1
	selectedTile = grid.GetTile(selectedPath[indexedSize] / grid.CellSize)

	if selectedTile.Occupant != null:
		while selectedTile.Occupant != null:
			# Well shit now we're in trouble
			# walk backwards from the current index
			indexedSize -= 1
			if indexedSize < 0:
				# if we've hit 0, then there are a whole bunch of units all in the way of this unit, so just end turn
				unit.QueueEndTurn()
				return

			selectedTile = grid.GetTile(selectedPath[indexedSize] / grid.CellSize)
			selectedPath.remove_at(selectedPath.size() - 1)


func GetAllValidPaths():
	pathfindingOptions.clear()

	var allUnitsAbleToBeTargeted = map.GetUnitsOnTeam(TargetingFlags)
	for potentialUnit in allUnitsAbleToBeTargeted:
		var path = grid.GetPathBetweenTwoUnits(unit, potentialUnit)
		if path.size() != 0: # Check against 0, because 0 means you can't path there
			var op = PathfindingOption.new()
			path.remove_at(0) # Remove the first entry, because that is the current tile this unit is on
			op.Unit = potentialUnit
			op.Path = path
			pathfindingOptions.append(op)

	pathfindingOptions.sort_custom(func(x,y) : return x.PathSize < y.PathSize)

func GetActionableTiles():
	var tilesWithinRange = grid.GetTilesWithinRange(targetUnit.GridPosition, ability.GetRange())
	tilesWithinRange = tilesWithinRange.filter(func(tile) : return tile.Occupant == null || (tile.Occupant == unit))
	tilesWithinRange = tilesWithinRange.filter(func(tile) : return !tile.IsWall)
	return tilesWithinRange

func FilterTilesByPath(_actionableTiles : Array[Tile]):
	var lowest = 1000000
	for tile in _actionableTiles:
		var path = pathfinding.get_point_path(unit.GridPosition, tile.Position)
		if path.size() < lowest && path.size() != 0: # Check 0 path size, because that indicates that there is no path to that tile
			selectedTile = tile
			selectedPath = path
			selectedPath.remove_at(0) # Remove the first entry, because that is the current tile this unit is on
			lowest = path.size()

func GetAbility():
	if unit.Abilities.size() == 0:
		return

	ability = unit.Abilities[0]

func TryCombat():
	if targetUnit == null:
		unit.QueueEndTurn()
		return

	if !ability.IsWithinRange(selectedTile.Position, targetUnit.GridPosition):
		unit.QueueEndTurn()
		return

	## default to the first ability
	#var ability = unit.Abilities[0]
	#if !ability.active:
	#print("EXECUTING ABILITY")
	var context = CombatLog.new()
	context.Construct(map, unit, ability)
	context.originTile = targetUnit.CurrentTile
	context.targetTiles.append(targetUnit.CurrentTile)
	ability.ExecuteAbility(context)

