extends ActionStep
class_name AbilityMoveStep


func Enter(_actionLog : ActionLog):
	super(_actionLog)
	var targeting = ability.TargetingData

	if ability.MovementData == null:
		return true

	ability.MovementData.Move(log.grid, source, log.actionOriginTile, log.actionDirection)
	return true
