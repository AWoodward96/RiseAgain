extends ActionStep
class_name HealStep

func Enter(_actionLog : ActionLog):
	super(_actionLog)

	# The heal action will automatically grab the right result, it just needs to be queued
	# This looks weird but it's right
	source.QueueHealAction(log)
	pass

func GetResults(_actionLog : ActionLog, _affectedTiles : Array[TileTargetedData]):
	if _actionLog.ability.HealData == null:
		return

	var returnArray : Array[HealStepResult]
	for tiles in _affectedTiles:
		var result = HealStepResult.new()
		result.AbilityData = _actionLog.ability
		result.TileTargetData = tiles
		result.Source = _actionLog.source
		result.Target = tiles.Tile.Occupant
		result.PreCalculate()
		returnArray.append(result)
	return returnArray
