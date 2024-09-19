extends ActionStep
class_name HealStep

func Enter(_actionLog : ActionLog):
	super(_actionLog)
	for results in _actionLog.actionResults:
		results.Ability_CalculateResult(ability, null)
		source.QueueHealAction(log)
		pass
