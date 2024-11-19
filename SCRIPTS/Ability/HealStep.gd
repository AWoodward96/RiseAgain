extends ActionStep
class_name HealStep

func Enter(_actionLog : ActionLog):
	super(_actionLog)
	for results in _actionLog.actionStepResults:
		source.QueueHealAction(log)
		pass

func GetResult(_actionLog : ActionLog, _specificTile : TileTargetedData):
	var result = HealStepResult.new()
	result.AbilityData = _actionLog.ability
	result.TileTargetData = _specificTile
	result.Source = _actionLog.source
	result.Target = _specificTile.Tile.Occupant
	result.PreCalculate()
	return result
