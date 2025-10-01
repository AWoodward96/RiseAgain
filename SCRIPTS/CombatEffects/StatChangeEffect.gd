extends CombatEffectTemplate
class_name StatChangeEffect
#  This is the parent class for stat changes
# There are StatChangeEffectTemplates which define which stats are changed before creating an instance of those templates

@export var StatChanges : Array[StatChangeEffectTemplate]

func CreateInstance(_sourceUnit : UnitInstance, _affectedUnit : UnitInstance,  _abilitySource : Ability, _actionLog : ActionLog):
	if _affectedUnit.Template.Descriptors.count(ImmunityDescriptor) > 0:
		return null

	var effectInstance = StatChangeEffectInstance.new()

	effectInstance.Template = self
	effectInstance.SourceUnit = _sourceUnit
	effectInstance.AffectedUnit = _affectedUnit
	effectInstance.AbilitySource = _abilitySource
	effectInstance.TurnsRemaining = Turns

	for effectTemplate in StatChanges:
		effectTemplate.CreateStatBuff(effectInstance, _sourceUnit, _affectedUnit, _actionLog)

	return effectInstance
