extends CombatEffectTemplate
class_name InvulnerableEffectTemplate

func CreateInstance(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance, _abilitySource : Ability, _actionLog : ActionLog):
	if _affectedUnit.Template.Descriptors.count(ImmunityDescriptor) > 0:
		return null

	var invulnInstance = InvulnerableEffectInstance.new()

	invulnInstance.Template = self
	invulnInstance.SourceUnit = _sourceUnit
	invulnInstance.AffectedUnit = _affectedUnit
	invulnInstance.TurnsRemaining = Turns

	return invulnInstance
