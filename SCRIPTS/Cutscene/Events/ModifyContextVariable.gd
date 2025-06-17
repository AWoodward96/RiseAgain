extends CutsceneEventBase
class_name ModifyContextVariable

enum ModType { Set, Add, Subtract, Multiply }
@export var variableName : String
@export var modType : ModType = ModType.Set
@export var mod : int

## A name of a variable known to be in context to use as the value of the mod instead of the above field
@export var contextmod : String

func Enter(_context : CutsceneContext):
	var variable = 0
	if _context.ContextDict.has(variableName):
		variable = _context.ContextDict[variableName]

	var variableChange = mod
	if contextmod != "" && _context.ContextDict.has(contextmod):
		variableChange = _context.ContextDict[contextmod]

	match modType:
		ModType.Set:
			variable = variableChange
		ModType.Add:
			variable += variableChange
		ModType.Subtract:
			variable -= variableChange
		ModType.Multiply:
			variable = variable * variableChange

	_context.ContextDict[variableName] = variable

	return true
