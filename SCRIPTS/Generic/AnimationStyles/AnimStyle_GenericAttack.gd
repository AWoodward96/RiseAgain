extends CombatAnimationStyleTemplate
class_name AnimStyle_GenericAttack

var movedTargets : Array[UnitInstance]

func Prepare(_direction : Vector2, _source : UnitInstance, _data):
	super(_direction, _source, _data)
	PlayPrepAnimations()
	pass

func Enter():
	super()

	source.PlayAttackAnimation(initialDirection)

	var dst = (initialDirection).normalized()
	dst = dst * (Juice.combatSequenceAttackOffset * GameSettingsTemplate.TILESIZE)
	source.position += dst

	movedTargets.clear()

	if actionLog != null:
		if !isRetaliation:
			var results = actionLog.GetResultsFromActionIndex(actionLog.actionStackIndex)
			for r in results:
				var damageStepResult = r as DamageStepResult
				if damageStepResult != null && damageStepResult.Target != null:
					damageStepResult.Target.position += dst
					movedTargets.append(damageStepResult.Target)
					pass
		else:
			for r in actionLog.responseResults:
				if r != null && r.Target != null:
					r.Target.position += dst
					movedTargets.append(r.Target)

	PlayJuice()
	return true

func Execute(_delta, _direction : Vector2):
	var desired = source.GridPosition * GameSettingsTemplate.TILESIZE

	var passSource = false
	# We should be off center now, move back towards your grid position
	source.position = lerp(source.position, (desired) as Vector2, Juice.combatSequenceReturnToOriginLerp * _delta)
	if source.position.distance_squared_to(desired) < (Juice.combatSequenceReturnToOriginLerp * Juice.combatSequenceReturnToOriginLerp):
		source.position = desired
		passSource = true

	var passTargets = true
	for unit in movedTargets:
		var targetDesired = unit.GridPosition * GameSettingsTemplate.TILESIZE
		unit.position = lerp(unit.position, (targetDesired) as Vector2, Juice.combatSequenceReturnToOriginLerp * _delta)
		if unit.position.distance_squared_to(targetDesired) < (Juice.combatSequenceReturnToOriginLerp * Juice.combatSequenceReturnToOriginLerp):
			unit.position = targetDesired
		else:
			passTargets = false

	return passSource && passTargets
