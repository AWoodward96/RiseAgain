extends CombatEffectTemplate
class_name OnFireEffectTemplate

@export var StackDamage : Array[int] = [0, -3, -5, -10]
@export var ExecutionStack : Array[ActionStep]
@export var VFX : PackedScene
@export var ActivelyOnFire : PackedScene


func GetDamageFromStacks(_stacks : int):
	if _stacks < 0:
		return 0

	if _stacks >= StackDamage.size():
		return StackDamage[StackDamage.size() - 1]

	return StackDamage[_stacks]

func CreateInstance(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance, _abilitySource : Ability, _actionLog : ActionLog):
	var newEffect = OnFireEffectInstance.new()
	# Stacks are handled when created in UnitInstance.Ignite
	newEffect.AffectedUnit = _affectedUnit
	newEffect.SourceUnit = _sourceUnit
	newEffect.AbilitySource = _abilitySource
	newEffect.Template = self
	newEffect.TurnsRemaining = Turns
	return newEffect
