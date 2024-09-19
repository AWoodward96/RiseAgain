extends ActionStep
class_name GainExpStep

func Enter(_actionLog : ActionLog):
	super(_actionLog)

	_actionLog.QueueExpGains()

func Execute(_delta):
	return log.source.IsStackFree
