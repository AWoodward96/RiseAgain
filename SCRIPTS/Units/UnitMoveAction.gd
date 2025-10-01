extends UnitActionBase
class_name UnitMoveAction

var Route : Array[Tile]
var DestinationTile : Tile
var MovementIndex
var MovementVelocity
var SpeedOverride : int = -1
var MoveFromAbility : bool = false
var Log : ActionLog
var CutsceneMove : bool = false
var AllowOccupantOverwrite : bool = false
var AnimationStyle : UnitSettingsTemplate.MovementAnimationStyle = UnitSettingsTemplate.MovementAnimationStyle.Normal
var TravelVector : Vector2 # The Vector representing movement from one point to the next
var JumpStart : Vector2
var JumpTimer : float = 0


func _Enter(_unit : UnitInstance, _map : Map):
	super(_unit, _map)
	MovementIndex = 0
	JumpTimer = 0

	# Maybe make a switch statement
	match AnimationStyle:
		UnitSettingsTemplate.MovementAnimationStyle.Normal:
			unit.footstepsSound.play()
		UnitSettingsTemplate.MovementAnimationStyle.Jump:
			unit.LeapSound.play()

	if Route.size() > 1:
		unit.facingDirection = GameSettingsTemplate.GetDirectionFromVector((Route[MovementIndex - 1].GlobalPosition - Route[MovementIndex - 2].GlobalPosition).normalized())
		TravelVector = Route[1].GlobalPosition - Route[0].GlobalPosition
		JumpStart = Route[0].GlobalPosition
	pass

func _Execute(_unit : UnitInstance, _delta):
	if Route.size() == 0:
		return true

	var speed = GameManager.GameSettings.CharacterTileMovemementSpeed
	if SpeedOverride != -1:
		speed = SpeedOverride

	var destination = Route[MovementIndex].GlobalPosition
	var distance = _unit.position.distance_squared_to(destination)

	Move(destination, distance, speed, _delta)
	UpdateAnimations(distance)

	var maximumDistanceTraveled = speed * _delta; # or "Maximum distance we can travel in one frame"

	var isAlliedTeam = map.currentTurn == GameSettingsTemplate.TeamID.ALLY

	# passes when we're closer to the destination than the maximum distance we can travel in one frame (ya know)
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
				map.grid.SetUnitGridPosition(unit, Route[MovementIndex].Position, true, AllowOccupantOverwrite)
				unit.LockInMovement(unit.CurrentTile)
				return true
			GameSettingsTemplate.TraversalResult.EndTurn:
				if unit.footstepsSound != null:
					unit.footstepsSound.stop()

				if unit != null && unit.currentHealth > 0 && !unit.IsDying:
					map.grid.SetUnitGridPosition(unit, Route[MovementIndex].Position, true, AllowOccupantOverwrite)

				unit.EndTurn()

				if isAlliedTeam:
					map.playercontroller.EnterSelectionState()
				return true

		MovementIndex += 1


		# Check for bonk on the next position
		if  MovementIndex < Route.size() && !Map.Current.grid.CanUnitFitOnTile(unit, Route[MovementIndex], unit.IsFlying, true, false):
			if (MoveFromAbility && MovementIndex == Route.size() - 1) || (!MoveFromAbility):
				# Get bonked loser
				if Route[MovementIndex].Occupant != null:
					Route[MovementIndex].Occupant.visual.PlayAlertedFromShroudAnimation()

				unit.PlayShockEmote()
				if Log != null:
					var curStep = Log.ability.executionStack[Log.actionStackIndex]
					if curStep is AbilityMoveStep:
						curStep.Bonked(Route[MovementIndex], Log)
						return true

				map.grid.SetUnitGridPosition(_unit, Route[MovementIndex - 1].Position, true, AllowOccupantOverwrite)
				unit.LockInMovement(Route[MovementIndex - 1])
				FinishMoving()
				return true

		if MovementIndex >= Route.size() :
			if DestinationTile != null:
				map.grid.SetUnitGridPosition(_unit, DestinationTile.Position, true, AllowOccupantOverwrite)
			else:
				push_error("Destination Tile is null for the move action of ", _unit.Template.DebugName ,". This will cause position desync and you need to fix this.")

			FinishMoving()
			return true
		else:
			TravelVector = Route[MovementIndex].GlobalPosition - Route[MovementIndex - 1].GlobalPosition
	return false

func FinishMoving():
	var isAlliedTeam = map.currentTurn == GameSettingsTemplate.TeamID.ALLY
	if unit.footstepsSound != null:
		unit.footstepsSound.stop()

	unit.TryPlayIdleAnimation()
	var diedToKillbox = unit.CheckKillbox()
	if isAlliedTeam && !CutsceneMove:
		if diedToKillbox: # If it's true, then this unit's fucking dead lmao
			map.playercontroller.EnterSelectionState()
		elif !MoveFromAbility:
			map.playercontroller.EnterContextMenuState()

func UpdateAnimations(_distance):
	# dont update the animation when we're not moving
	if _distance <= 0:
		return

	match AnimationStyle:
		UnitSettingsTemplate.MovementAnimationStyle.Normal:
			unit.PlayAnimation(UnitSettingsTemplate.GetMovementAnimationFromVector(MovementVelocity))
		UnitSettingsTemplate.MovementAnimationStyle.Pushed:
			unit.PlayAnimation(UnitSettingsTemplate.ANIM_TAKE_DAMAGE)
		UnitSettingsTemplate.MovementAnimationStyle.Jump:

			if _distance > (TravelVector.length_squared() / 2):
				if TravelVector.y < 0:
					unit.PlayAnimation(UnitSettingsTemplate.ANIM_JUMP_BACK_UP)
				else:
					unit.PlayAnimation(UnitSettingsTemplate.ANIM_JUMP_FRONT_UP)
			else:
				if TravelVector.y < 0:
					unit.PlayAnimation(UnitSettingsTemplate.ANIM_JUMP_BACK_DOWN)
				else:
					unit.PlayAnimation(UnitSettingsTemplate.ANIM_JUMP_FRONT_DOWN)

			if unit.visual.AnimationWorkComplete:
				unit.visual.visual.flip_h = TravelVector.x < 0
			pass

func Move(_destination : Vector2, _distance : float, _speed : float, _delta : float):
	match AnimationStyle:
		UnitSettingsTemplate.MovementAnimationStyle.Normal, UnitSettingsTemplate.MovementAnimationStyle.Pushed:
			MovementVelocity = (_destination - unit.position).normalized() * _speed
			unit.position += MovementVelocity * _delta
		UnitSettingsTemplate.MovementAnimationStyle.Jump:
			if JumpTimer <= 1:
				var height = sin(PI * JumpTimer) * (JumpStart.distance_to(_destination) * 0.3)
				unit.position = JumpStart.lerp(_destination, JumpTimer) - Vector2(0, height)
				JumpTimer += _delta / 1
			else:
				unit.LandSound.play()
			pass

func _Exit():
	if unit.visual.AnimationWorkComplete:
		unit.visual.visual.flip_h = false

	if unit.footstepsSound != null:
		unit.footstepsSound.stop()
	pass
