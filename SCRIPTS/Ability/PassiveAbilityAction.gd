extends Object
class_name PassiveAbilityAction

var executionStack : Array[ActionStep]
var log : ActionLog

var priority : int = 0
var ability : Ability
var source : UnitInstance


func TryExecute(_delta : float):
	if log.actionStackIndex < 0:
		log.actionStackIndex = 0
		executionStack[log.actionStackIndex].Enter(log)


	if log.actionStackIndex < executionStack.size():
		if executionStack[log.actionStackIndex].Execute(_delta):
			log.actionStackIndex += 1
			if log.actionStackIndex < executionStack.size():
				executionStack[log.actionStackIndex].Enter(log)
			else:
				return true

	return false

func BuildResults():
	# REMEMBER:
	# The execution stack here is NOT the Ability's execution stack
	# SOMETIMES IT CAN BE
	# But it's seperate for a reason - the passive does something the ability doesn't.
	# For instance, an ability might set someone on fire, but the onfire passive action deals the damage
	# Which is FUNDAMENTALLY DIFFERENT
	log.actionStepResults.clear()
	var index = 0
	for step in executionStack:
		var resultsArr = step.GetResults(log, log.affectedTiles)
		if resultsArr != null:
			for res in resultsArr:
				if res is ActionStepResult:
					res.StepIndex = index
					log.actionStepResults.append(res)
				else:
					push_error("Ability Step: " + str(step.get_script()) + " - attached to ability " + ability.name + " has an improper ActionStepResult and cannot be previewed.")
		index += 1

static func Construct(_source : UnitInstance, _abilitySource : Ability, _priority : int = 0):
	var newAction = PassiveAbilityAction.new()
	newAction.log = ActionLog.Construct(Map.Current.grid, _source, _abilitySource)
	newAction.log.actionStackIndex = -1
	newAction.priority = _priority
	# In some instances, this may turn into a null - we'll deal with that when we get there
	newAction.ability = _abilitySource
	newAction.source = _source
	return newAction
