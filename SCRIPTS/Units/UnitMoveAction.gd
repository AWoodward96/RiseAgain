extends UnitActionBase
class_name UnitMoveAction

var Route : Array[Tile]
var DestinationTile : Tile
var MovementIndex
var MovementVelocity
var SpeedOverride : int = -1
var MoveFromAbility : bool = false
var CutsceneMove : bool = false
var AllowOccupantOverwrite : bool = false

func _Enter(_unit : UnitInstance, _map : Map):
	super(_unit, _map)
	MovementIndex = 0
	MovementVelocity = 0

	if Route.size() > 1:
		_unit.facingDirection = GameSettingsTemplate.GetDirectionFromVector((Route[MovementIndex - 1].GlobalPosition - Route[MovementIndex - 2].GlobalPosition).normalized())


func _Execute(_unit : UnitInstance, _delta):
	if Route.size() == 0:
		return true

	var speed = GameManager.GameSettings.CharacterTileMovemementSpeed
	if SpeedOverride != -1:
		speed = SpeedOverride

	var destination = Route[MovementIndex].GlobalPosition
	var distance = _unit.position.distance_squared_to(destination)


	MovementVelocity = (destination - _unit.position).normalized() * speed

	_unit.PlayAnimation(UnitSettingsTemplate.GetMovementAnimationFromVector(MovementVelocity))

	_unit.position += MovementVelocity * _delta
	var maximumDistanceTraveled = speed * _delta;

	var isAlliedTeam = map.currentTurn == GameSettingsTemplate.TeamID.ALLY

	if distance < (maximumDistanceTraveled * maximumDistanceTraveled) :
		var traversalResult = Route[MovementIndex].OnUnitTraversed(_unit)
		match traversalResult:
			GameSettingsTemplate.TraversalResult.OK:
				pass
			GameSettingsTemplate.TraversalResult.HealthModified:
				if unit == null || unit.currentHealth <= 0:
					# They fucking died lmao
					if isAlliedTeam:
						map.playercontroller.EnterSelectionState()
					return true
				pass
			GameSettingsTemplate.TraversalResult.EndMovement:
				# The units movement has been interrupted and we're good
				map.grid.SetUnitGridPosition(unit, Route[MovementIndex].Position, true, AllowOccupantOverwrite)
				unit.LockInMovement()
				return true
			GameSettingsTemplate.TraversalResult.EndTurn:
				map.grid.SetUnitGridPosition(unit, Route[MovementIndex].Position, true, AllowOccupantOverwrite)
				unit.EndTurn()
				if isAlliedTeam:
					map.playercontroller.EnterSelectionState()
				return true

		#AudioFootstep.play()
		MovementIndex += 1
		if MovementIndex >= Route.size() :
			unit.PlayAnimation(UnitSettingsTemplate.ANIM_IDLE)

			if DestinationTile != null:
				map.grid.SetUnitGridPosition(_unit, DestinationTile.Position, true, AllowOccupantOverwrite)
			else:
				push_error("Destination Tile is null for the move action of ", _unit.Template.DebugName ,". This will cause position desync and you need to fix this.")

			var diedToKillbox = _unit.CheckKillbox()
			if isAlliedTeam && !CutsceneMove:
				if diedToKillbox: # If it's true, then this unit's fucking dead lmao
					map.playercontroller.EnterSelectionState()
				elif !MoveFromAbility:
					map.playercontroller.EnterContextMenuState()
			return true
	return false
