extends ActionStep
class_name HealStep

func Enter(_actionLog : ActionLog):
	super(_actionLog)
	for results in _actionLog.actionResults:
		results.Ability_CalculateResult(Map.Current.rng, ability, null)
		source.QueueHealAction(log)
		pass
