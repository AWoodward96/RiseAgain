extends PassiveUnitDeathListener
class_name PassiveZombifyOnKill

@export var UnitPairs : Array[UnitPair]
@export var SpawnedUnitAI : AIBehaviorBase
@export var SpawnedUnitAggroBehavior : AlwaysAggro


func OnDeath(_unitThatDied : UnitInstance, _context : DamageStepResult):
	if Map.Current == null:
		return

	# If this unit died to some unknown result - just ignore it
	if _context == null:
		return

	# If it wasn't us that dealt the damage - go away
	if _context.Source != ability.ownerUnit:
		return

	for u in UnitPairs:
		if u.Unit1 == _unitThatDied.Template:

			# This is not normal, but I think it's okay. It's a very specific condition and a very specific sequence
			var newPassiveAction = PassiveAbilityAction.Construct(ability.ownerUnit, ability) as PassiveAbilityAction
			newPassiveAction.log.actionOriginTile = _unitThatDied.CurrentTile

			var cameraFocusStep = FocusCameraStep.new()
			cameraFocusStep.Instant = false
			newPassiveAction.executionStack.append(cameraFocusStep)

			var delay = DelayStep.new()
			delay.time = 0.5
			newPassiveAction.executionStack.append(delay)

			var popup = PlayAbilityPopupStep.new()
			newPassiveAction.executionStack.append(popup)

			var newSummonStep = SummonStep.new()
			newSummonStep.AggroBehavior = SpawnedUnitAggroBehavior
			newSummonStep.AI = SpawnedUnitAI
			newSummonStep.UnitToSummon = u.Unit2
			newPassiveAction.executionStack.append(newSummonStep)

			var secondDelay = DelayStep.new()
			secondDelay.time = 0.5
			newPassiveAction.executionStack.append(secondDelay)

			map.AppendPassiveAction(newPassiveAction)

			#var zombifiedUnit = map.CreateUnit(u.Unit2, _unitThatDied.Level)
			#map.InitializeUnit(zombifiedUnit, _unitThatDied.GridPosition, GameSettingsTemplate.TeamID.ENEMY)
			#zombifiedUnit.SetAI(SpawnedUnitAI, SpawnedUnitAggroBehavior)
			## End the zombified Unit's turn so that it doesn't mess up the turn order
			#zombifiedUnit.EndTurn()
			#Juice.CreateEffectPopup(zombifiedUnit.CurrentTile, self)
			return # Don't spawn more than one unit here
	pass
