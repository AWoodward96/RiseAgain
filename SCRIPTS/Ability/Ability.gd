extends UnitUsable
class_name Ability

signal AbilityActionComplete

# Standard: The normal abilities that get unlocked at certain level breakpoints
# Weapon: A Units 'Auto-Attack' ability.
#	If another Equippable is added to a Unit, their existing Equippable Ability gets deleted
#	All Equippables should have the Damage Grants Focus bool set to true - but it's available as an option to be false for any edge cases
# Tactical: A utility focused Ability that every Unit can use
enum AbilityType { Standard, Weapon, Tactical, Passive, Deathrattle }
enum AbilitySpeed { Normal, Fast, Slow }

@export var type : AbilityType
@export var focusCost : int = 1
@export var isXFocusCost : bool = false # This will deduct the entire focus of the unit after they're done
@export var limitedUsage : int = -1 # -1 means there is no limited usage
@export var usageRestoredByCampfire : int = 0

@export var ability_speed : AbilitySpeed = AbilitySpeed.Normal
@export var executionStack : Array[ActionStep]
@export var damageGrantsFocus : bool = false
@export var passiveListeners : Array[PassiveListenerBase]

var remainingCooldown : int = 0
var remainingUsages : int = 0
var kills : int = 0
var usages : int = 0

func Initialize(_unitOwner : UnitInstance):
	super(_unitOwner)
	if limitedUsage != -1:
		remainingUsages = limitedUsage

	# this is the price I pay for generic components :)
	for c in componentArray:
		if "ability" in c:
			c.ability = self
	# It would probably be proper to convert all of the components to a base AbilityType - but currently only one component is actually using this
	# Sooooooooo

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
		remainingCooldown = focusCost
		usages += 1

	if _actionLog.actionStackIndex < executionStack.size():
		if executionStack[_actionLog.actionStackIndex].Execute(_delta):
			_actionLog.actionStackIndex += 1
			if _actionLog.actionStackIndex < executionStack.size():
				executionStack[_actionLog.actionStackIndex ].Enter(_actionLog)
			else:
				if ability_speed != AbilitySpeed.Fast:
					_actionLog.source.QueueEndTurn()

				if isXFocusCost && _actionLog.source != null:
					_actionLog.source.ModifyFocus(-_actionLog.source.currentFocus)

				AbilityActionComplete.emit()


func SetMap(_map : Map):
	super(_map)
	for passive in passiveListeners:
		if passive != null:
			passive.RegisterListener(self, _map)


func OnRest():
	if limitedUsage != -1:
		remainingUsages += usageRestoredByCampfire
		remainingUsages = clampi(remainingUsages, 0, limitedUsage)

	remainingCooldown = 0

func OnOwnerUnitTurnStart():
	remainingCooldown -= 1

func _to_string():
	return self.name


func ToJSON():
	var dict = {
		"prefab" : self.scene_file_path,
		"remainingUsages" : remainingUsages,
		"remainingCooldown" : remainingCooldown,
		"usages" : usages,
		"kills" : kills
	}
	return dict


func FromJSON(_dict : Dictionary):
	remainingUsages = _dict["remainingUsages"]
	if _dict.has("remainingCooldown"): remainingCooldown = _dict["remainingCooldown"]
	if _dict.has("kills"): kills = int(_dict["kills"])
	if _dict.has("usages"): usages = int(_dict["usages"])
