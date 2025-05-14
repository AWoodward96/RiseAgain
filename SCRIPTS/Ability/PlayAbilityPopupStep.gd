extends ActionStep
class_name PlayAbilityPopupStep

func Enter(_actionLog : ActionLog):
	super(_actionLog)
	Juice.CreateAbilityPopup(log.actionOriginTile, log.ability)
