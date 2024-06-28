extends ActionStep
class_name HealStep

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

			damageResult.Ability_CalculateResult(ability, null)
			log.actionResults.append(damageResult)
			source.QueueHealAction(log)
		pass
