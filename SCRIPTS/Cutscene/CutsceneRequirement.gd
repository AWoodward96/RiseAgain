extends CutsceneEventBase
class_name CutsceneRequirement

@export var requirements : Array[RequirementBase]
@export var events : Array[CutsceneEventBase]

var index = -1

# Requirements have to pass to enter
func Enter(_context : CutsceneContext):
	for r in requirements:
		var res = r.CheckRequirement(_context)
		if !res && !r.NOT || res && r.NOT:
			return false

	index = -1
	return true

func Execute(_delta : float, _context : CutsceneContext):
	if events.size() == 0:
		return true

	if index < 0:
		if events[0].Enter(_context):
			index = 0
		else:
			return false

	if index < events.size():
		if events[index].Execute(_delta, _context):
			index += 1
			if index < events.size():
				events[index].Enter(_context)
			else:
				return true
	return false
