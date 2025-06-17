extends ChanceModifier
class_name CMCutsceneContext

@export var contextVariableName : String
@export var modType : ModType

func Modify(_value, _context):
	if _context is CutsceneContext:
		var contextValue = _context.ContextDict[contextVariableName]
		match modType:
			ModType.Set:
				return contextValue
			ModType.Add:
				return _value + contextValue
			ModType.Multiply:
				return _value * contextValue
			ModType.Subtract:
				return _value - contextValue

	return _value
