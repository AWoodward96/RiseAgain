extends UnitActionBase
class_name UnitMoveAction

var Route : PackedVector2Array
var DestinationTile : Tile
var MovementIndex
var MovementVelocity

func _Enter(_unit : UnitInstance, _map : Map):
	MovementIndex = 0
	MovementVelocity = 0
	if DestinationTile != null:
		_map.grid.SetUnitGridPosition(_unit, DestinationTile.Position, false)

	if Route.size() > 1:
		_unit.facingDirection = GameSettingsTemplate.CastDirectionEnumToInt(GameSettingsTemplate.GetDirectionFromVector((Route[MovementIndex - 1] - Route[MovementIndex - 2]).normalized()))


func _Execute(_unit : UnitInstance, _delta):
	var speed = GameManager.GameSettings.CharacterTileMovemementSpeed
	var destination = Route[MovementIndex]
	var distance = _unit.position.distance_squared_to(destination)
	MovementVelocity = (destination - _unit.position).normalized() * speed
	_unit.position += MovementVelocity * _delta
	var maximumDistanceTraveled = speed * _delta;

	if distance < (maximumDistanceTraveled * maximumDistanceTraveled) :
		#AudioFootstep.play()
		MovementIndex += 1
		if MovementIndex >= Route.size() :
			_unit.position = Route[MovementIndex - 1]

			return true
	return false
