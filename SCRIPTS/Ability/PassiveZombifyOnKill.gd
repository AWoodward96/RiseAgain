extends PassiveUnitDeathListener
class_name PassiveZombifyOnKill

@export var UnitPairs : Array[UnitPair]
@export var SpawnedUnitAI : AIBehaviorBase
@export var SpawnedUnitAggroBehavior : AlwaysAggro


func OnDeath(_unitThatDied : UnitInstance, _context : DamageStepResult):
	if Map.Current == null:
		return

	var passes = CheckRequirements(_unitThatDied, _context)
	if !passes:
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
			return # Don't spawn more than one unit here
	pass
