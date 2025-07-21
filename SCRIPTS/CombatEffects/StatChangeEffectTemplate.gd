extends Resource
class_name StatChangeEffectTemplate

@export_group("Stat Change Data")
@export var Stat : StatTemplate
@export var FlatValue : int

@export_group("Derivatives")
@export var DerivedFromUnit : CombatEffectTemplate.EffectTargetType
@export var DerivedFromStat : StatTemplate
@export var SignedPercentageValue : float


func CreateStatBuff(_parent : Node2D, _sourceUnit : UnitInstance, _affectedUnit : UnitInstance, _actionLog : ActionLog):
	var buff = StatBuff.new()
	_parent.add_child(buff)

	var value = FlatValue

	# this has to be set for anything to work so
	if DerivedFromStat != null && SignedPercentageValue != 0:
		match DerivedFromUnit:
			CombatEffectTemplate.EffectTargetType.Source:
				value += _sourceUnit.GetWorkingStat(DerivedFromStat)
				value = ceili(value * SignedPercentageValue)
			CombatEffectTemplate.EffectTargetType.Targets:
				# I am interpreting 'Targets' in this scenario to be the affected unit
				# I sure hope this doesn't come to bite me in the ass later
				value += _affectedUnit.GetWorkingStat(DerivedFromStat)
				value = ceili(value * SignedPercentageValue)
			CombatEffectTemplate.EffectTargetType.Both:
				push_error("StatChangeEffect applied by ability: " + _actionLog.ability.to_string() + " has it's effect target type set to Both. This is not supported (how would a stat buff be derived from two different sources??). Please fix")
				pass


	buff.Value = value
	buff.Stat = Stat
	return buff
