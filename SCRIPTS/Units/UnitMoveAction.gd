extends UnitActionBase
class_name UnitMoveAction

var Route : Array[Tile]
var DestinationTile : Tile
var MovementIndex

var movementData : MovementData
var Log : ActionLog


func _Enter(_unit : UnitInstance, _map : Map):
	super(_unit, _map)
	MovementIndex = 0
	Route = movementData.Route
	DestinationTile = movementData.DestinationTile
	Log = movementData.Log


	var travelVector = Vector2.ZERO
	if Route.size() > 1:
		unit.facingDirection = GameSettingsTemplate.GetDirectionFromVector((Route[MovementIndex - 1].GlobalPosition - Route[MovementIndex - 2].GlobalPosition).normalized())
		travelVector = Route[1].GlobalPosition - Route[0].GlobalPosition

	if movementData.MovementAnimationStyle != null:
		movementData.MovementAnimationStyle.Prepare(travelVector, unit, movementData)

	pass

func _Execute(_unit : UnitInstance, _delta):
	if Route.size() == 0:
		return true

	var speed = GameManager.GameSettings.CharacterTileMovemementSpeed
	if movementData.SpeedOverride != -1:
		speed = movementData.SpeedOverride

	var destination = Route[MovementIndex].GlobalPosition
	var distance = _unit.position.distance_squared_to(destination)

	if movementData.MovementAnimationStyle != null:
		movementData.MovementAnimationStyle.Execute(_delta, destination)

	var maximumDistanceTraveled = speed * _delta; # or "Maximum distance we can travel in one frame"

	var isAlliedTeam = map.currentTurn == GameSettingsTemplate.TeamID.ALLY

	# passes when we're closer to the destination than the maximum distance we can travel in one frame
	if distance < (maximumDistanceTraveled * maximumDistanceTraveled) :
		var traversalResult = Route[MovementIndex].OnUnitTraversed(_unit)
		match traversalResult:
			GameSettingsTemplate.TraversalResult.OK:
				pass
			GameSettingsTemplate.TraversalResult.HealthModified:
				if unit.footstepsSound != null:
					unit.footstepsSound.stop()

				unit.LockInMovement(Route[Route.size() - 1])
				if unit == null || unit.currentHealth <= 0:
					# They fucking died lmao
					if isAlliedTeam:
						map.playercontroller.EnterSelectionState()
					return true
				pass
			GameSettingsTemplate.TraversalResult.EndMovement:
				if unit.footstepsSound != null:
					unit.footstepsSound.stop()
				# The units movement has been interrupted and we're good
				map.grid.SetUnitGridPosition(unit, Route[MovementIndex].Position, true, movementData.AllowOccupantOverwrite)
				unit.LockInMovement(unit.CurrentTile)
				return true
			GameSettingsTemplate.TraversalResult.EndTurn:
				if unit.footstepsSound != null:
					unit.footstepsSound.stop()

				if unit != null && unit.currentHealth > 0 && !unit.IsDying:
					map.grid.SetUnitGridPosition(unit, Route[MovementIndex].Position, true, movementData.AllowOccupantOverwrite)

				unit.EndTurn()

				if isAlliedTeam:
					map.playercontroller.EnterSelectionState()
				return true

		MovementIndex += 1


		# Check for bonk on the next position
		if !movementData.IsPush:
			if  MovementIndex < Route.size() && !Map.Current.grid.CanUnitFitOnTile(unit, Route[MovementIndex], unit.IsFlying, true, false):
				if (movementData.MoveFromAbility && MovementIndex == Route.size() - 1) || (!movementData.MoveFromAbility):
					# Get bonked loser
					if Route[MovementIndex].Occupant != null:
						Route[MovementIndex].Occupant.visual.PlayAlertedFromShroudAnimation()

					unit.PlayShockEmote()
					if movementData.Log != null:
						var curStep = Log.ability.executionStack[Log.actionStackIndex]
						if curStep is AbilityMoveStep:
							curStep.Bonked(Route[MovementIndex], Log)
							return true

					map.grid.SetUnitGridPosition(_unit, Route[MovementIndex - 1].Position, true, movementData.AllowOccupantOverwrite)
					unit.LockInMovement(Route[MovementIndex - 1])
					unit.position = DestinationTile.Position
					FinishMoving()
					return true

		if MovementIndex >= Route.size() :
			if DestinationTile != null:
				map.grid.SetUnitGridPosition(_unit, DestinationTile.Position, true, movementData.AllowOccupantOverwrite)
			else:
				push_error("Destination Tile is null for the move action of ", _unit.Template.DebugName ,". This will cause position desync and you need to fix this.")

			FinishMoving()
			return true
	return false

func FinishMoving():
	if movementData.MovementAnimationStyle != null:
		movementData.MovementAnimationStyle.Exit()

	var isAlliedTeam = map.currentTurn == GameSettingsTemplate.TeamID.ALLY
	if unit.footstepsSound != null:
		unit.footstepsSound.stop()

	unit.TryPlayIdleAnimation()
	var diedToKillbox = unit.CheckKillbox()
	if isAlliedTeam && !movementData.CutsceneMove:
		if diedToKillbox: # If it's true, then this unit's fucking dead lmao
			map.playercontroller.EnterSelectionState()
		elif !movementData.MoveFromAbility:
			map.playercontroller.EnterContextMenuState()


func _Exit():
	if movementData.MovementAnimationStyle != null:
		movementData.MovementAnimationStyle.Exit()
	pass
