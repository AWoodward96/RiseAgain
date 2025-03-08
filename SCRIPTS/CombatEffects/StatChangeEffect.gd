extends CombatEffectTemplate
class_name StatChangeEffect

@export var StatChanges : Array[StatChangeEffectTemplate]

func CreateInstance(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance, _actionLog : ActionLog):
	if _affectedUnit.Template.Descriptors.count(ImmunityDescriptor) > 0:
		return null

	var effectInstance = StatChangeEffectInstance.new()

	effectInstance.Template = self
	effectInstance.SourceUnit = _sourceUnit
	effectInstance.AffectedUnit = _affectedUnit
	if _actionLog != null && _actionLog.ability != null:
		effectInstance.AbilitySource = _actionLog.ability
	effectInstance.TurnsRemaining = Turns

	for effectTemplate in StatChanges:
		effectTemplate.CreateStatBuff(effectInstance, _sourceUnit, _affectedUnit, _actionLog)

	return effectInstance
