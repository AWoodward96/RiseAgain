extends ActionStep
class_name PlayAbilityPopupStep

@export var PlayAtUnit : bool = true

func Enter(_actionLog : ActionLog):
	super(_actionLog)
	if PlayAtUnit && log.source != null:
		Juice.CreateAbilityPopup(log.source.CurrentTile, log.ability)
	else:
		Juice.CreateAbilityPopup(log.actionOriginTile, log.ability)
