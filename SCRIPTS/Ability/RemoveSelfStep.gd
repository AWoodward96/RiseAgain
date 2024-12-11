extends ActionStep
class_name RemoveSelfStep


func Enter(_actionLog : ActionLog):
	super(_actionLog)

	Map.Current.RemoveUnitFromMap(_actionLog.source)
