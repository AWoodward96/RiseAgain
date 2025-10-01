extends ActionStep
class_name RepeatStep

@export var repeatStack : Array[ActionStep]
@export var repeatAmount : int

# Be warned, I'm not sure if this works anymore lmfao

func Enter(_actionLog : ActionLog):
	super(_actionLog)
	_actionLog.subActionStackIndex = -1

func Execute(_delta):
	if log.subActionStackIndex < 0:
		log.subActionStackIndex = 0
		repeatStack[log.subActionStackIndex].Enter(log)

	if log.subActionStackIndex < repeatStack.size():
		if repeatStack[log.subActionStackIndex].Execute(_delta):
			log.subActionStackIndex += 1
			if log.subActionStackIndex < repeatStack.size():
				repeatStack[log.subActionStackIndex].Enter(log)

		return false

	repeatAmount -= 1
	if repeatAmount > 0:
		log.subActionStackIndex = -1
		return false

	return true


func GetResults(_actionLog : ActionLog, _affectedTiles : Array[TileTargetedData]):
	var returnResults : Array[RepeatStepResult]
	for tileData in _affectedTiles:
		var result = RepeatStepResult.new()
		result.Source = _actionLog.source
		result.Target = tileData.Tile.Occupant
		result.TileTargetData = tileData
		if _actionLog.source != null:
			result.RepeatAmount = repeatAmount

		for step in repeatStack:
			var newResult = step.GetResults(_actionLog, _affectedTiles)
			result.SubStepResult.append(newResult)

	return returnResults
