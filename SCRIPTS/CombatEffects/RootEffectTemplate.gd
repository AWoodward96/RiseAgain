extends CombatEffectTemplate
class_name RootEffectTemplate



func CreateInstance(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance, _abilitySource : Ability, _actionLog : ActionLog):
	if _affectedUnit.Template.Descriptors.count(ImmunityDescriptor) > 0:
		return null

	var rootEffect = RootEffectInstance.new()

	rootEffect.Template = self
	rootEffect.SourceUnit = _sourceUnit
	rootEffect.AffectedUnit = _affectedUnit
	rootEffect.TurnsRemaining = Turns

	return rootEffect
