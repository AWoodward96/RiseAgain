extends ActionStep
class_name ReqStep

@export var requirements : Array[RequirementBase]
@export var stackIfPassed : Array[ActionStep]

var passed
var stackIndex = -1

func Enter(_actionLog : ActionLog):
	super(_actionLog)

	stackIndex = -1
	passed = true
	for r in requirements:
		var rPass = r.CheckRequirement(_actionLog)
		if  !r.NOT:
			passed = passed && rPass
		elif r.NOT:
			passed = passed && !rPass


func Execute(_delta):
	if !passed:
		return true

	if stackIndex < 0:
		stackIndex = 0
		stackIfPassed[stackIndex].Enter(log)

	if stackIndex < stackIfPassed.size():
		if stackIfPassed[stackIndex].Execute(_delta):
			stackIndex += 1
			if stackIndex < stackIfPassed.size():
				stackIfPassed[stackIndex].Enter(log)
		return false

	return true
