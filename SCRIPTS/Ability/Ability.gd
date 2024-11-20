extends UnitUsable
class_name Ability

signal AbilityActionComplete

# Standard: The normal abilities that get unlocked at certain level breakpoints
# Weapon: A Units 'Auto-Attack' ability.
#	If another Equippable is added to a Unit, their existing Equippable Ability gets deleted
#	All Equippables should have the Damage Grants Focus bool set to true - but it's available as an option to be false for any edge cases
# Tactical: A utility focused Ability that every Unit can use
enum AbilityType { Standard, Weapon, Tactical }


@export var type : AbilityType
@export var focusCost : int = 1
@export var limitedUsage : int = -1 # -1 means there is no limited usage
@export var usageRestoredByCampfire : int = 0

@export var executionStack : Array[ActionStep]
@export var autoEndTurn : bool = true
@export var damageGrantsFocus : bool = false

var remainingUsages : int = 0

func Initialize(_unitOwner : UnitInstance):
	super(_unitOwner)
	if limitedUsage != -1:
		remainingUsages = limitedUsage

func TryExecute(_actionLog : ActionLog, _delta : float):
	if _actionLog.actionStackIndex < 0:
		# Auto-finish any ability with a bad amount of usages left
		if limitedUsage != -1 && remainingUsages <= 0:
			AbilityActionComplete.emit()
			return

		_actionLog.actionStackIndex = 0
		executionStack[_actionLog.actionStackIndex].Enter(_actionLog)
		_actionLog.source.ModifyFocus(-focusCost)
		if limitedUsage != -1:
			remainingUsages -= 1

	if _actionLog.actionStackIndex < executionStack.size():
		if executionStack[_actionLog.actionStackIndex].Execute(_delta):
			_actionLog.actionStackIndex += 1
			if _actionLog.actionStackIndex < executionStack.size():
				executionStack[_actionLog.actionStackIndex ].Enter(_actionLog)
			else:
				if autoEndTurn:
					_actionLog.source.QueueEndTurn()
				AbilityActionComplete.emit()


func OnRest():
	if limitedUsage != -1:
		remainingUsages += usageRestoredByCampfire
		remainingUsages = clampi(remainingUsages, 0, limitedUsage)

func _to_string():
	return self.name
