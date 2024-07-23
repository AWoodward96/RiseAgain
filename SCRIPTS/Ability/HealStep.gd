extends ActionStep
class_name HealStep

func Enter(_actionLog : ActionLog):
	super(_actionLog)
	var targeting = ability.TargetingData
	for tileData in _actionLog.affectedTiles:
		if tileData.Tile.Occupant != null:
			var target = tileData.Tile.Occupant
			if targeting != null && !targeting.OnCorrectTeam(log.source, target):
				continue

			var damageResult = ActionResult.new()
			damageResult.Source = source
			damageResult.Target = target
			damageResult.TileTargetData = tileData.Tile.AsTargetData()

			damageResult.Ability_CalculateResult(ability, null)
			log.actionResults.append(damageResult)
			source.QueueHealAction(log)
		pass
