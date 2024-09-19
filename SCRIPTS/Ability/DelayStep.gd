extends ActionStep
class_name DelayStep

@export var time : float = 1
var delay

func Enter(_actionLog : ActionLog):
	super(_actionLog)

	delay = false
	await _actionLog.source.get_tree().create_timer(time).timeout
	delay = true
	pass

func Execute(_delta):
	return delay
