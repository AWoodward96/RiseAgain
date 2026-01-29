extends CutsceneEventBase
class_name RandomChanceEvent

@export var DecisionOptions : Array[VariableChance]
@export var clearOnExit : bool = true

var index = -1
var enter = false
var rolledChanceStack : VariableChanceStack

func Enter(_context : CutsceneContext):
	var rng = Map.Current.mapRNG
	if GameManager.CurrentCampaign != null:
		rng = GameManager.CurrentCampaign.CampaignRng
	rolledChanceStack = GameSettingsTemplate.RollVariableChanceTable(DecisionOptions, rng, _context)
	return true

func Execute(_delta : float, _context : CutsceneContext):
	# Wait for the decision to be made, and then execute the decisions cutscene stack accordingly
	if rolledChanceStack == null:
		return false


	var events = rolledChanceStack.CutsceneStack
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
