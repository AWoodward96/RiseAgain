extends CombatEffectTemplate
class_name TauntEffectTemplate



func CreateInstance(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance, _abilitySource : Ability, _actionLog : ActionLog):
	if _affectedUnit.Template.Descriptors.count(ImmunityDescriptor) > 0:
		return null

	var tauntEffect = TauntEffectInstance.new()

	tauntEffect.Template = self
	tauntEffect.SourceUnit = _sourceUnit
	tauntEffect.AffectedUnit = _affectedUnit


	tauntEffect.TurnsRemaining = Turns

	return tauntEffect
