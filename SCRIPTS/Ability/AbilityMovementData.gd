extends Node2D
class_name AbilityMovementComponent

# Three types of movement
# TargetTile is just the tile that you targeted for the ability
# DirectionalReletive is in the direction that you have selected for a Directional Attack
# InverseDirectional is in the opposite direction of a Directional Attack (like for a backstep or a backflip)

enum AbilityMovementType { TargetTile, DirectionalRelative, InverseDirectional }

@export var type : AbilityMovementType
@export var stoppedByWalls : bool = true
@export var movementAmount : int

var positionalOffset : Vector2
var destinationTile : Tile


# returns an array that says how this unit should move for this action
# if the array is empty then it is not a valid move
func PreviewMove(_grid : Grid, _unit : UnitInstance, _selectedTile : Tile, _direction : GameSettingsTemplate.Direction):
	destinationTile = null

	# Set the positional offset to be a half-cell size so that the route that we take goes through the center of each tile instead of on the corner
	positionalOffset = Vector2(_grid.CellSize / 2, _grid.CellSize / 2)
	match type:
		AbilityMovementType.TargetTile:
			# The TargetTile type is automatically not stopped by walls, as it would be too difficult to detect where
			# the unit should stop moving in a Standard or ShapedFree target selection
			return GetRoute_TargetTile(_unit.CurrentTile, _selectedTile)
		AbilityMovementType.DirectionalRelative:
			# Okay this one is a little harder
			return GetRoute_DirectionalRelative(_grid, _unit, _direction)
		AbilityMovementType.InverseDirectional:
			return GetRoute_DirectionalRelative(_grid, _unit, _direction, true)

	return []

func GetRoute_TargetTile(_origin : Tile, _destination : Tile):
	if _destination.Occupant == null && !_destination.IsWall:
		destinationTile = _destination
		return Array([_origin, _destination])
	return []

func GetRoute_DirectionalRelative(_grid : Grid, _unit : UnitInstance, _direction : GameSettingsTemplate.Direction, _inverse : bool = false):
	# Okay this one is a little harder
	var route : Array[Tile] = []
	var origin = _unit.CurrentTile
	var workingTile = origin
	var directionVector = GameSettingsTemplate.GetVectorFromDirection(_direction)
	if _inverse:
		directionVector = GameSettingsTemplate.GetInverseVectorFromDirection(_direction)

	route.append(origin)
	for i in movementAmount:
		var tile = _grid.GetTile(workingTile.Position + directionVector)
		if tile != null:
			if stoppedByWalls && tile.IsWall:
				destinationTile = workingTile
				break

			route.append(tile)
			workingTile = tile

	# currently, workingTile should be the last tile added to the route
	var occupantValidator = workingTile.Occupant == null || (workingTile.Occupant != null && workingTile.Occupant == _unit)
	if !occupantValidator:
		return []

	destinationTile = workingTile
	return route


func Move(_grid : Grid, _unit : UnitInstance, _selectedTile : Tile, _direction : GameSettingsTemplate.Direction, _speedOverride : int = -1):
	# Set the positional offset to zero because actual unit movement does not go through the center
	positionalOffset = Vector2.ZERO
	destinationTile = null

	var route : Array[Tile] = []
	match type:
		AbilityMovementType.TargetTile:
			# The TargetTile type is automatically not stopped by walls, as it would be too difficult to detect where
			# the unit should stop moving in a Standard or ShapedFree target selection
			route = GetRoute_TargetTile(_unit.CurrentTile, _selectedTile)
		AbilityMovementType.DirectionalRelative:
			# Okay this one is a little harder
			route = GetRoute_DirectionalRelative(_grid, _unit, _direction)
		AbilityMovementType.InverseDirectional:
			route = GetRoute_DirectionalRelative(_grid, _unit, _direction, true)

	_unit.MoveCharacterToNode(route, destinationTile, _speedOverride)
	return route
