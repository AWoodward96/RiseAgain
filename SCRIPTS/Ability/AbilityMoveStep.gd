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
		# force the turnstart tile to be where they end up because that's the breaks
		log.source.TurnStartTile = ability.MovementData.destinationTile
		return true

	return false

func GetResult(_actionLog : ActionLog, _specificTile : TileTargetedData):
	var result = AbilityMoveResult.new()
	result.unitUsable = _actionLog.ability
	result.shapedDirection = _actionLog.actionDirection
	result.TileTargetData = _actionLog.actionOriginTile.AsTargetData()
	result.Source = _actionLog.source
	return result
