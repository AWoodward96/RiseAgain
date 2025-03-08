extends Resource
class_name CutsceneTemplate

@export var startingRequirement : Array[RequirementBase]
@export var events : Array[CutsceneEventBase]
@export var repeatable : bool = false
@export var autoComplete : bool = true

var index = -1
var enter = false
var forceComplete = false

func CanStart(_context):
	for req in startingRequirement:
		var res = req.CheckRequirement(_context)
		if res && req.NOT || !res && !req.NOT:
			return false

	return true


func Execute(_delta : float, _context : CutsceneContext):
	if forceComplete:
		return true

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
