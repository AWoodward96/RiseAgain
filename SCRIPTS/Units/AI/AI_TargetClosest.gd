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


var grid : Grid
var pathfinding  : AStarGrid2D
var selectedTile : Tile
var selectedPath : PackedVector2Array

var item : Item

var pathfindingOptions : Array[PathfindingOption]

func StartTurn(_map : Map, _unit : UnitInstance):
	super(_map, _unit)
	grid = _map.grid
	pathfinding = map.grid.Pathfinding

	selectedTile = null
	selectedPath.clear()

	# STEP ZERO:
	# Check if this enemy even has an ability to use. If they don't, then there's nothing to do
	GetEquippedItem()
	if item == null:
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
			TruncatePathBasedOnMovement(option.Path, unitMovement)
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

# Cuts down the path to the units movement, and takes into account occupied tiles so that this unit doesn't move on top of another unit
func TruncatePathBasedOnMovement(_path, _currentMovement):
	selectedPath = _path
	selectedPath = selectedPath.slice(0, _currentMovement)

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

	var allUnitsAbleToBeTargeted : Array[UnitInstance]

	# This parallel index is used to track FlagIndex in the PathfindingOption
	var parallelIndex : Array[int]
	var index = 0
	for targetingFlags in Flags:
		var units = map.GetUnitsOnTeam(targetingFlags.Team)
		if targetingFlags.Descriptor != null:
			units = units.filter(func(x) : return x.Template.Descriptors.find(targetingFlags.Descriptor) != -1)

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
	var tilesWithinRange = grid.GetTilesWithinRange(targetUnit.GridPosition, item.GetRange())
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

func GetEquippedItem():
	if unit.Inventory.size() == 0:
		return

	item = unit.EquippedItem

func TryCombat():
	if targetUnit == null:
		unit.QueueEndTurn()
		return

	if !item.IsWithinRange(selectedTile.Position, targetUnit.GridPosition):
		unit.QueueEndTurn()
		return

	## default to the first ability
	if item != null && item.ItemDamageData != null:
		var log = ActionLog.Construct(unit, item)
		log.actionOriginTile = targetUnit.CurrentTile # This is the target we're attacking, so the origin is here
		log.sourceTile = selectedTile	# Remember, we're pathfinding to this tile so the source has to be from here
		log.affectedTiles.append(targetUnit.CurrentTile)
		log.damageData = item.ItemDamageData
		map.playercontroller.EnterActionExecutionState(log)
	else:
		push_error("Unit is attempting to TryCombat with TargetClosest AI, without an Item that does damage")

