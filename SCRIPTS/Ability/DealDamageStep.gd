extends ActionStep
class_name DealDamageStep

@export var useAttackAction : bool = true
@export var useDefendAction : bool = true
@export var damageDataOverride : DamageDataResource


func Enter(_actionLog : ActionLog):
	super(_actionLog)
	var targeting = ability.TargetingData

	if useAttackAction:
		source.QueueAttackSequence(log.actionOriginTile.GlobalPosition, log)

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

			if useDefendAction:
				target.QueueDefenseSequence(source.global_position, damageResult)
			else:
				target.DoCombat(damageResult)
		pass
