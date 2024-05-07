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
var selectedPath

var ability : AbilityInstance

func StartTurn(_map : Map, _unit : UnitInstance):
	map = _map
	grid = _map.grid
	pathfinding = map.grid.Pathfinding
	unit = _unit

	selectedTile = null
	selectedPath = null

	# STEP ZERO:
	# Check if this enemy even has an ability to use. If they don't, then there's nothing to do
	GetAbility()
	if ability == null:
		unit.QueueEndTurn()
		return

	# STEP ONE:
	# Figure out which unit we'll be targeting this turn
	targetUnit = map.GetClosestUnitToUnit(unit, TargetingFlags)
	if targetUnit == null:
		unit.QueueEndTurn()
		return

	# STEP TWO:
	# Now that we know who we're targeting select a tile thats in range to try and move to
	var actionableTiles = GetActionableTiles()
	if actionableTiles == null || actionableTiles.size() == 0:
		unit.QueueEndTurn()
		return

	# EARLY EXIT NOTICE:
	# IF WE'RE ALREADY STANDING ON AN ACTIONABLE TILE, JUST STAY THERE, NO PATHFINDING NECESSARY
	for option in actionableTiles:
		if option.Occupant == unit:
			TryCombat()
			return

	# STEP THREE:
	# Now filter down by however much movement we need to actually get to those actionable tiles
	# This method should take all actionable tiles, and return the one that is easiest to get to
	FilterTilesByPath(actionableTiles)

	# This shouldn't happen, but if there are no tiles or paths, then just end turn
	if selectedTile == null || selectedPath == null:
		unit.QueueEndTurn()
		return

	# STEP FOUR:
	# Truncate down the paths that we just set based on how much movement this current Unit has
	var currentMovement = unit.GetUnitMovement()
	selectedPath = selectedPath.slice(0, currentMovement)
	selectedTile = grid.GetTile(selectedPath[selectedPath.size() - 1] / grid.CellSize)

	# STEP FIVE:
	# MOVE
	unit.MoveCharacterToNode(selectedPath, selectedTile)
	TryCombat()
	pass


func GetActionableTiles():
	var tilesWithinRange = grid.GetTilesWithinRange(targetUnit.GridPosition, ability.GetRange())
	tilesWithinRange = tilesWithinRange.filter(func(tile) : return tile.Occupant == null || (tile.Occupant == unit))
	tilesWithinRange = tilesWithinRange.filter(func(tile) : return !tile.IsWall)
	return tilesWithinRange

func FilterTilesByPath(_actionableTiles : Array[Tile]):
	var lowest = 1000000
	for t in _actionableTiles:
		var path = pathfinding.get_point_path(unit.GridPosition, t.Position)
		if path.size() < lowest:
			selectedTile = t
			selectedPath = path
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
	var context = AbilityContext.new()
	context.Construct(map, unit, ability)
	context.originTile = targetUnit.CurrentTile
	context.targetTiles.append(targetUnit.CurrentTile)
	ability.ExecuteAbility(context)

