extends ActionStep
class_name HealStep

func Enter(_actionLog : ActionLog):
	super(_actionLog)
	print("heal step update")

	# The heal action will automatically grab the right result, it just needs to be queued
	# This looks weird but it's right
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
