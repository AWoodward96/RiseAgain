extends AbilityStep
class_name GainExpStep

func Enter(_actionLog : ActionLog):
	super(_actionLog)

	_actionLog.QueueExpGains()

func Execute():
	return log.source.IsStackFree
