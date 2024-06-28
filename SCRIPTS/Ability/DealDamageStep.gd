extends AbilityStep
class_name DealDamageStep

@export var useDefendAction : bool
@export var damageDataOverride : DamageDataResource


func Enter(_actionLog : ActionLog):
	super(_actionLog)
	var targeting = ability.TargetingData
	for tile in _actionLog.affectedTiles:
		if tile.Occupant != null:
			var target = tile.Occupant
			if targeting != null && !targeting.OnCorrectTeam(log.source, target):
				continue

			var damageResult = ActionResult.new()
			damageResult.Source = source
			damageResult.Target = target

			var damageData
			if damageDataOverride != null:
				damageData = damageDataOverride
			else:
				damageData = ability.UsableDamageData

			damageResult.Ability_CalculateResult(ability, damageData)
			log.actionResults.append(damageResult)
			source.QueueAttackSequence(target.global_position, log)
			target.QueueDefenseSequence(source.global_position, damageResult)
		pass
