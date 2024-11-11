extends CombatEffectTemplate
class_name EnergizedEffect


func CreateInstance(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance, _actionLog : ActionLog):
	if _affectedUnit.Template.Descriptors.count(ImmunityDescriptor) > 0:
		return null

	var armorInstance = EnergizedEffectInstance.new()

	armorInstance.Template = self
	armorInstance.SourceUnit = _sourceUnit
	armorInstance.AffectedUnit = _affectedUnit
	armorInstance.TurnsRemaining = Turns

	return armorInstance
