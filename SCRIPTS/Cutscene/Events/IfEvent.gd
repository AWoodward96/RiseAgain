extends CutsceneEventBase
class_name IfEvent

@export var Conditions : Array[RequirementBase]
@export var True : Array[CutsceneEventBase]
@export var False : Array[CutsceneEventBase]

var evaluatedCondition : bool
var steps : Array[CutsceneEventBase]
var index = -1
var enter = false

# Requirements have to pass to enter
func Enter(_context : CutsceneContext):
	steps = True
	for r in Conditions:
		var res = r.CheckRequirement(_context)
		if !res && !r.NOT || res && r.NOT:
			steps = False
			break

	index = -1
	return true

func Execute(_delta : float, _context : CutsceneContext):
	if steps.size() == 0:
		return true

	if index < 0:
		if steps[0].Enter(_context):
			index = 0
		else:
			return false

	if index < steps.size():
		if enter:
			if steps[index].Enter(_context):
				enter = false
		else:
			if steps[index].Execute(_delta, _context):
				steps[index].Exit(_context) # Exit doesn't wait
				index += 1
				if index < steps.size():
					enter = true
				else:
					return true
	return false
