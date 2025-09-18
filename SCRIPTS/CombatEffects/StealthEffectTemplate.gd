extends CombatEffectTemplate
class_name StealthEffectTemplate


func CreateInstance(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance, _actionLog : ActionLog):
	if _affectedUnit.Template.Descriptors.count(ImmunityDescriptor) > 0:
		return null

	var stealthInstance = StealthEffectInstance.new()
	stealthInstance.Template = self
	stealthInstance.SourceUnit = _sourceUnit
	stealthInstance.AffectedUnit = _affectedUnit
	stealthInstance.AbilitySource = _actionLog.ability
	stealthInstance.TurnsRemaining = Turns
	return stealthInstance
