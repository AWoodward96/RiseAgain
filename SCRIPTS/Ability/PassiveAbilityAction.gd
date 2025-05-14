extends Object
class_name PassiveAbilityAction

var executionStack : Array[ActionStep]
var log : ActionLog

var priority : int = 0
var ability : Ability
var source : UnitInstance
var cachedSourceStats : Dictionary = {}	# unit might die before this so it's important to construct


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


static func Construct(_source : UnitInstance, _abilitySource : Ability, _priority : int = 0):
	var newAction = PassiveAbilityAction.new()
	newAction.log = ActionLog.Construct(Map.Current.grid, _source, _abilitySource)
	newAction.log.actionStackIndex = -1
	newAction.priority = _priority
	# In some instances, this may turn into a null - we'll deal with that when we get there
	newAction.ability = _abilitySource
	newAction.source = _source
	return newAction
