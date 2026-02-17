extends Node2D
class_name AbilityMovementComponent

# Three types of movement
# TargetTile is just the tile that you targeted for the ability
# DirectionalReletive is in the direction that you have selected for a Directional Attack
# InverseDirectional is in the opposite direction of a Directional Attack (like for a backstep or a backflip)

enum AbilityMovementType { TargetTile, DirectionalRelative, InverseDirectional }

@export var type : AbilityMovementType
@export var stoppedByWalls : bool = true

## If True, the route tries to draw a path from the unit's current position to the destination.
## If False, the route just uses the start and end position - no inbetween. Good for jumping.
## If False, stoppedByWalls is not used
@export var drawPath : bool = true
@export var movementAmount : int

var positionalOffset : Vector2
var destinationTile : Tile


# returns an array that says how this unit should move for this action
# if the array is empty then it is not a valid move
func PreviewMove(_grid : Grid, _unit : UnitInstance, _origin : Tile, _selectedTile : Tile, _atRange: int, _direction : GameSettingsTemplate.Direction):
	destinationTile = null

	# Set the positional offset to be a half-cell size so that the route that we take goes through the center of each tile instead of on the corner
	positionalOffset = Vector2i(_grid.CellSize / 2, _grid.CellSize / 2)
	match type:
		AbilityMovementType.TargetTile:
			# The TargetTile type is automatically not stopped by walls, as it would be too difficult to detect where
			# the unit should stop moving in a Standard or ShapedFree target selection
			return GetRoute_TargetTile(_unit, _unit.CurrentTile, _selectedTile)
		AbilityMovementType.DirectionalRelative:
			# Okay this one is a little harder
			return GetRoute_DirectionalRelative(_grid, _unit, _origin, _atRange, _direction)
		AbilityMovementType.InverseDirectional:
			return GetRoute_DirectionalRelative(_grid, _unit, _origin, _atRange, _direction, true)

	return []

func GetRoute_TargetTile(_unit : UnitInstance, _origin : Tile, _destination : Tile):
	var ar : Array[Tile] = []
	if (_destination.Occupant == null ||
		(_destination.Occupant != null && _destination.Occupant.ShroudedFromPlayer) ||
		(_destination.Occupant == _unit)) && !_destination.IsWall && _destination.Position.y != 0:
		destinationTile = _destination
		ar.append(_origin)
		ar.append(_destination)
		return ar
	return ar

func GetRoute_DirectionalRelative(_grid : Grid, _unit : UnitInstance, _origin : Tile, _atRange : int, _direction : GameSettingsTemplate.Direction, _inverse : bool = false):
	# Okay this one is a little harder
	var route : Array[Tile] = []
	var directionVector = GameSettingsTemplate.GetVectorFromDirection(_direction)
	if _inverse:
		directionVector = GameSettingsTemplate.GetInverseVectorFromDirection(_direction)


	var workingTile = _origin
	route.append(_origin)
	if drawPath:
		for i in movementAmount:
			var tile = _grid.GetTile(workingTile.Position + directionVector)
			if tile != null:
				if stoppedByWalls && (tile.IsWall || tile.Position.y == 0):
					destinationTile = workingTile
					break

				route.append(tile)
				workingTile = tile
	else:
		workingTile = _grid.GetTile(_origin.Position + directionVector * _atRange)
		var tmp = _grid.GetTile(workingTile.Position + (directionVector * movementAmount))
		if tmp.Position.y == 0 || (tmp.IsWall && !_unit.IsFlying):
			# units can't get stuck in walls plz
			return []

		workingTile = tmp
		route.append(workingTile)

	# currently, workingTile should be the last tile added to the route
	var occupantValidator = workingTile.Occupant == null || (workingTile.Occupant != null && workingTile.Occupant == _unit) || (workingTile.Occupant != null && workingTile.Occupant.ShroudedFromPlayer)
	if !occupantValidator:
		return []

	destinationTile = workingTile
	return route


func Move(_grid : Grid, _unit : UnitInstance, _selectedTile : Tile, _origin : Tile, _atRange : int, _direction : GameSettingsTemplate.Direction, _actionLog : ActionLog, _speedOverride : int = -1, _animationStyle : MovementAnimationStyleTemplate = null):
	# Set the positional offset to zero because actual unit movement does not go through the center
	positionalOffset = Vector2.ZERO
	destinationTile = null

	var route : Array[Tile] = []
	match type:
		AbilityMovementType.TargetTile:
			# The TargetTile type is automatically not stopped by walls, as it would be too difficult to detect where
			# the unit should stop moving in a Standard or ShapedFree target selection
			route = GetRoute_TargetTile(_unit, _unit.CurrentTile, _selectedTile)
		AbilityMovementType.DirectionalRelative:
			# Okay this one is a little harder
			route = GetRoute_DirectionalRelative(_grid, _unit, _origin, _atRange, _direction)
		AbilityMovementType.InverseDirectional:
			route = GetRoute_DirectionalRelative(_grid, _unit, _origin, _atRange, _direction, true)

	var movementData = MovementData.Construct(route, destinationTile, _animationStyle)
	movementData.AssignAbilityData(_actionLog.ability, _actionLog)
	_unit.MoveCharacterToNode(movementData)
	return route
