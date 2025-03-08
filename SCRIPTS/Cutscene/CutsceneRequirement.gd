extends CutsceneEventBase
class_name CutsceneRequirement

@export var requirements : Array[RequirementBase]
@export var events : Array[CutsceneEventBase]

var index = -1
var enter = false

# Requirements have to pass to enter
func Enter(_context : CutsceneContext):
	for r in requirements:
		if r == null:
			continue

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
		if enter:
			if events[index].Enter(_context):
				enter = false
		else:
			if events[index].Execute(_delta, _context):
				events[index].Exit(_context) # Exit doesn't wait
				index += 1
				if index < events.size():
					enter = true
				else:
					return true
	return false
