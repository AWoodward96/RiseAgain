extends MadLib
class_name CutsceneContextMadlib

@export var Lib = "CONTEXTVAR"
@export var CutsceneContextVariable : String

func ApplyMadLib(_string : String, _context):
	if _context is CutsceneContext:
		var res = str(_context.ContextDict[CutsceneContextVariable])
		_string = _string.format({Lib : res})

	return _string
