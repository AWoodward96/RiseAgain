extends CombatEffectTemplate
class_name StunEffectTemplate


func CreateInstance(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance, _abilitySource : Ability, _actionLog : ActionLog):
	if _affectedUnit.Template.Descriptors.count(ImmunityDescriptor) > 0:
		return null

	var armorInstance = StunEffectInstance.new()
	armorInstance.Template = self
	armorInstance.SourceUnit = _sourceUnit
	armorInstance.AffectedUnit = _affectedUnit
	armorInstance.AbilitySource = _actionLog.ability
	armorInstance.TurnsRemaining = Turns
	return armorInstance
