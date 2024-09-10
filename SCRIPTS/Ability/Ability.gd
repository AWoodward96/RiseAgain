extends UnitUsable
class_name Ability

signal AbilityActionComplete


@export var unlockLevel : int = 2
@export var focusCost : int = 1
@export var executionStack : Array[ActionStep]
@export var autoEndTurn : bool = true
@export var damageGrantsFocus : bool = false


func TryExecute(_actionLog : ActionLog):
	if _actionLog.abilityStackIndex < 0:
		_actionLog.abilityStackIndex = 0
		executionStack[_actionLog.abilityStackIndex].Enter(_actionLog)
		_actionLog.source.ModifyFocus(-focusCost)

	if _actionLog.abilityStackIndex < executionStack.size():
		if executionStack[_actionLog.abilityStackIndex].Execute():
			_actionLog.abilityStackIndex += 1
			if _actionLog.abilityStackIndex < executionStack.size():
				executionStack[_actionLog.abilityStackIndex].Enter(_actionLog)
			else:
				if autoEndTurn:
					_actionLog.source.QueueEndTurn()
				AbilityActionComplete.emit()
