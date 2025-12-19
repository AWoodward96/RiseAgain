extends CombatEffectTemplate
class_name TurnStartHealEffectTemplate


# Ideally this would be divorced from the heal component on the node.
# Unfortunately, I've not made that change and I don't know if it's necessary or not
# For now we're going with this: Use the Abilities heal data to apply the heal

#@export var UseAbilitiesHealData : bool = true
@export var HealOnApply : bool = false

### Does this heal a unit if they're already at full hp?
@export var AllowHealAtFull : bool = false
#@export_category("Heal Data If Not Using Ability")
#@export var FlatHeal : int
#@export var ScalingStat : StatTemplate
#@export var ScalingModType : DamageData.EModificationType
#@export var ScalingMod : float


func CreateInstance(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance,  _abilitySource : Ability, _actionLog : ActionLog):
	var newEffect = TurnStartHealEffectInstance.new()
	# Stacks are handled when created in UnitInstance.Ignite
	newEffect.AffectedUnit = _affectedUnit
	newEffect.SourceUnit = _sourceUnit
	newEffect.AbilitySource = _abilitySource
	newEffect.Template = self
	newEffect.TurnsRemaining = Turns
	return newEffect
