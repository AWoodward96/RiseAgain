extends CutsceneEventBase
class_name ShowEventDecision

@export var DecisionOptions : Array[EventDecision]
@export var clearOnExit : bool = true

var decisionSelected = false
var decisionIndex = -1
var index = -1
var enter = false

func Enter(_context : CutsceneContext):
	CutsceneManager.ShowEventDecision(DecisionOptions, _context)
	CutsceneManager.EventDecisionChosen.connect(DecisionSelected)
	decisionSelected = false
	return true

func Execute(_delta : float, _context : CutsceneContext):
	# Wait for the decision to be made, and then execute the decisions cutscene stack accordingly
	if !decisionSelected:
		return false

	var decision = DecisionOptions[decisionIndex]
	var events = decision.resultActionStack
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

func DecisionSelected(_int : int):
	CutsceneManager.HideEventPrompt()
	decisionSelected = true
	decisionIndex = _int
	index = -1
	pass

func Exit(_context : CutsceneContext):
	if clearOnExit:
		CutsceneManager.HideEventPrompt()

	CutsceneManager.EventDecisionChosen.disconnect(DecisionSelected)
	return true
