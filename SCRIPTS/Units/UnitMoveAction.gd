extends UnitActionBase
class_name UnitMoveAction

var Route : Array[Tile]
var DestinationTile : Tile
var MovementIndex
var MovementVelocity
var SpeedOverride : int = -1

func _Enter(_unit : UnitInstance, _map : Map):
	MovementIndex = 0
	MovementVelocity = 0
	if DestinationTile != null:
		_map.grid.SetUnitGridPosition(_unit, DestinationTile.Position, false)
	else:
		push_error("Destination Tile is null for the move action of ", _unit.Template.DebugName ,". This will cause position desync and you need to fix this.")

	if Route.size() > 1:
		_unit.facingDirection = GameSettingsTemplate.GetDirectionFromVector((Route[MovementIndex - 1].GlobalPosition - Route[MovementIndex - 2].GlobalPosition).normalized())


func _Execute(_unit : UnitInstance, _delta):
	var speed = GameManager.GameSettings.CharacterTileMovemementSpeed
	if SpeedOverride != -1:
		speed = SpeedOverride

	var destination = Route[MovementIndex].GlobalPosition
	var distance = _unit.position.distance_squared_to(destination)
	MovementVelocity = (destination - _unit.position).normalized() * speed
	_unit.position += MovementVelocity * _delta
	var maximumDistanceTraveled = speed * _delta;

	if distance < (maximumDistanceTraveled * maximumDistanceTraveled) :
		#AudioFootstep.play()
		MovementIndex += 1
		if MovementIndex >= Route.size() :
			_unit.position = Route[MovementIndex - 1].GlobalPosition

			return true
	return false
