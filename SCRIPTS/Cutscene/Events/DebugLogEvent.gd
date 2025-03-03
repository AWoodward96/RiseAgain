extends CutsceneEventBase
class_name DebugLogEvent

@export var debug : String

func Enter(_context : CutsceneContext):
	print(debug)
	return true
