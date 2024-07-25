class_name EnemyAIOption

const TIER_AMOUNT = 100
const KILL_TIER_AMOUNT = 101 # Weighed only 1 higher than other tiers - just so it can stick out as the best option more oftan than not

var weight : int

var canKill : bool
var unitWillRetaliate : bool
var canDealDamage : bool
var damageAmount : int

var flagIndex : int
var totalFlags : int

var roughPath : PackedVector2Array # Rough path is the direct path to the target unit, without taking into account other units
var path : PackedVector2Array		# The actual path, taking other units into consideration. This is what the enemy should use to move to a target

var targetUnit : UnitInstance
var sourceUnit : UnitInstance

# not always equal to targetUnit.CurrentTile
var tileToMoveTo : Tile
var tileToAttack : Tile
var manhattanDistance : int

var unitUsable : UnitUsable
var valid : bool = false
var map : Map



func Update(_source : UnitInstance, _target : UnitInstance, _map : Map):
	# We fight like hell only to get so far gd

	map = _map
	sourceUnit = _source
	targetUnit = _target
	unitUsable = sourceUnit.EquippedItem

	CheckIfMovementNeeded(sourceUnit.GridPosition)

	# We need to get all of the possible options for attacking this target
	roughPath = _map.grid.GetPathBetweenTwoUnits(_source, _target)
	if roughPath.size() == 0:
		# If it's 0, there is no path between these two units that is valid.
		# If the MovementNeeded check fails, then this unit option is invalid and won't be used
		return
	roughPath.remove_at(0)  # Remove the first entry, because that is the current tile this unit is on

	# Okay so we think we can get to the target unit right now.
	# Issue is, that doesn't mean that we can ACTUALLY hit them. There could be units in the way, or other nonsense that we don't know how to deal with
	var actionableTiles = GetActionableTiles(unitUsable.GetRange())
	if actionableTiles == null || actionableTiles.size() == 0:
		# This might happen if a melee unit only has one valid tile they can path through, and there's a unit on that spot
		# In that case, truncate to a closer position.
		valid = true
		TruncatePathToMovement(roughPath)
		return

	# Okay so we have a list of actionableTiles - check which one is the closest
	var lowest = 1000000
	var selectedPath
	for tile in actionableTiles:
		var workingPath = map.grid.Pathfinding.get_point_path(sourceUnit.GridPosition, tile.Position)
		if workingPath.size() < lowest && workingPath.size() != 0: # Check 0 path size, because that indicates that there is no path to that tile
			selectedPath = workingPath
			selectedPath.remove_at(0) # Remove the first entry, because that is the current tile this unit is on
			lowest = workingPath.size()

	if selectedPath != null && selectedPath.size() != 0:
		valid = true
		path = selectedPath
		TruncatePathToMovement(path)
		CheckIfMovementNeeded(path[path.size() - 1] / map.grid.CellSize)
	else:
		valid = true
		TruncatePathToMovement(roughPath)

	pass


func CheckIfMovementNeeded(_origin : Vector2i):
	# First, check if we even need to move in order to hit the target
	var itemRange = unitUsable.GetRange()
	manhattanDistance = map.grid.GetManhattanDistance(_origin, targetUnit.GridPosition)
	if manhattanDistance >= itemRange.x && manhattanDistance <= itemRange.y:
		# Congrats we have a valid attack strategy
		valid = true
		SetValidAttack(map.grid.GetTile(_origin), targetUnit.CurrentTile)


func SetValidAttack(_tileToMoveTo : Tile, _tileToAttack : Tile):
	tileToMoveTo = _tileToMoveTo
	tileToAttack = _tileToAttack
	var targetUnitRange = targetUnit.EquippedItem.GetRange()
	if manhattanDistance >= targetUnitRange.x && manhattanDistance <= targetUnitRange.y:
		unitWillRetaliate = true

	var tileData = tileToAttack.AsTargetData()
	damageAmount = GameManager.GameSettings.UnitDamageCalculation(sourceUnit, targetUnit, unitUsable.UsableDamageData, 1)
	canKill = targetUnit.currentHealth <= damageAmount
	canDealDamage = damageAmount > 0 # This could cause some fuckyness with 'no damage' attacks but we'll see


func UpdateWeight():
	weight = 0

	if canKill: weight += KILL_TIER_AMOUNT
	if canDealDamage : weight += TIER_AMOUNT
	if !unitWillRetaliate && canDealDamage : weight += TIER_AMOUNT

	weight += damageAmount
	weight += (TIER_AMOUNT * ((totalFlags - 1) - flagIndex))

func TruncatePathToMovement(_path : Array[Vector2i]):
	if _path.size() == 0:
		return

	# Take the rough path, and start truncating it. Bring it down to the movement of the source Unit, and move backwards if there are tiles you can't stand on
	path = _path.slice(0, sourceUnit.GetUnitMovement())

	var indexedSize = path.size() - 1
	var selectedTile =  map.grid.GetTile(path[indexedSize] / map.grid.CellSize)

	if selectedTile.Occupant != null:
		while selectedTile.Occupant != null:
			# Well shit now we're in trouble
			# walk backwards from the current index
			indexedSize -= 1
			if indexedSize < 0:
				# if we've hit 0, then there are a whole bunch of units all in the way of this unit
				path.clear()
				selectedTile = sourceUnit.CurrentTile
				return

			selectedTile = map.grid.GetTile(path[indexedSize] / map.grid.CellSize)
			path.remove_at(path.size() - 1)

	tileToMoveTo = selectedTile
	pass

func GetActionableTiles(_range : Vector2i):
	var tilesWithinRange = map.grid.GetTilesWithinRange(targetUnit.GridPosition, _range)
	tilesWithinRange = tilesWithinRange.filter(func(tile) : return tile.Occupant == null || tile.Occupant == sourceUnit)
	tilesWithinRange = tilesWithinRange.filter(func(tile) : return !tile.IsWall)
	return tilesWithinRange
