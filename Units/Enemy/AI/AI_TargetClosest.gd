extends AIBehaviorBase
class_name AITargetClosest

# ------------AI Explanation------------
# This AI should be really dumb.
# It should only target the closet player, regardless of if they can actually damage them
# A more threatening, more interesting AI, would be SmartTargetClosest, where it'd prioritize units it could actually damage
# ---------------------------------------

@export_flags("ALLY", "ENEMY", "NEUTRAL") var TargetingFlags : int = 0
@export var RememberTarget : bool
@export var TEMP_Range : Vector2i

var targetUnit : UnitInstance


var grid : Grid
var pathfinding  : AStarGrid2D
var selectedTile : Tile
var selectedPath
var withinRange


func RunTurn(_map : Map, _unit : UnitInstance):
	map = _map
	grid = _map.grid
	pathfinding = map.grid.Pathfinding
	unit = _unit

	selectedTile = null
	selectedPath = null
	withinRange = false

	# STEP ONE:
	# Figure out which unit we'll be targeting this turn
	targetUnit = map.GetClosestUnitToUnit(unit, TargetingFlags)
	if targetUnit == null:
		unit.EndTurn()
		return

	# STEP TWO:
	# Now that we know who we're targeting select a tile thats in range to try and move to
	var actionableTiles = GetActionableTiles()
	if actionableTiles == null || actionableTiles.size() == 0:
		unit.EndTurn()
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
		unit.EndTurn()
		return

	# STEP FOUR:
	# Truncate down the paths that we just set based on how much movement this current Unit has
	var currentMovement = unit.GetUnitMovement()
	if selectedPath.size() < currentMovement:
		withinRange = true
	selectedPath = selectedPath.slice(0, currentMovement)
	selectedTile = grid.GetTile(selectedPath[selectedPath.size() - 1] / grid.CellSize)

	# STEP FIVE:
	# MOVE
	unit.MoveCharacterToNode(selectedPath, selectedTile)
	TryCombat()
	pass


func GetActionableTiles():
	var tilesWithinRange = grid.GetTilesWithinRange(targetUnit.GridPosition, TEMP_Range)
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

func TryCombat():
	if unit.Abilities.size() == 0:
		unit.EndTurn()

	if !withinRange:
		unit.EndTurn()

	# default to the first ability
	var ability = unit.Abilities[0]
	if !ability.active:
		print("EXECUTING ABILITY")
		var context = AbilityContext.new()
		context.Construct(map, unit, ability)
		context.target = targetUnit
		ability.ExecuteAbility(unit, map, context)

