extends CutsceneEventBase
class_name ReadOrWriteToMapPersist

enum ReadOrWrite { Read, Write }

@export var Function : ReadOrWrite = ReadOrWrite.Read
@export var PersistVariableString : String
@export var ContextVariableString : String
@export var autoSave : bool

func Enter(_context : CutsceneContext):
	var mapPersist = PersistDataManager.GetMapPersistData(Map.Current)
	if Function == ReadOrWrite.Read:
		if mapPersist != null:
			if mapPersist.has(PersistVariableString):
				_context.ContextDict[ContextVariableString] = int(mapPersist[PersistVariableString])
			else:
				push_warning("Couldn't find a persist variable with the name: " + PersistVariableString + ". If this is the first time you've looked for it, ignore this warning. Defaulting to 0")
				_context.ContextDict[ContextVariableString] = int(0)
	else:
		mapPersist[PersistVariableString] = _context.ContextDict[ContextVariableString]
		PersistDataManager.SaveMapPersistData(Map.Current, mapPersist, autoSave)
	return true
