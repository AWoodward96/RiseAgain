extends ActionStep
class_name AbilityMoveStep

@export var WaitForStackFree : bool = true
@export var SpeedOverride : int = -1

func Enter(_actionLog : ActionLog):
	super(_actionLog)

	if ability.MovementData == null:
		return true

	ability.MovementData.Move(log.grid, source, log.actionOriginTile, log.actionDirection, SpeedOverride)
	return true

func Execute(_delta):
	if !WaitForStackFree:
		return true

	if log.source.IsStackFree:
		return true

	return false
