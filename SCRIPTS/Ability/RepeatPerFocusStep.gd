extends ActionStep
class_name RepeatPerFocusStep

@export var repeatStack : Array[ActionStep]

var focusTotal = 0

func Enter(_actionLog : ActionLog):
	super(_actionLog)
	focusTotal = log.source.currentFocus
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

	focusTotal -= 1
	if focusTotal > 0:
		log.subActionStackIndex = -1
		return false

	return true


func GetResult(_actionLog : ActionLog, _specificTile : TileTargetedData):
	var result = RepeatPerFocusStepResult.new()
	result.Source = _actionLog.source
	result.Target = _specificTile.Tile.Occupant
	result.TileTargetData = _specificTile
	if _actionLog.source != null:
		result.FocusAmount = _actionLog.source.currentFocus

	for step in repeatStack:
		var newResult = step.GetResult(_actionLog, _specificTile)
		result.SubStepResult.append(newResult)

	return result
