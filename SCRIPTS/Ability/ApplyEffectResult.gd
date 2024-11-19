extends ActionStepResult
class_name ApplyEffectResult

var Template : CombatEffectTemplate


func PreviewResult(_map : Map):
	if Template.AffectedTargets == Template.EffectTargetType.Source || Template.AffectedTargets == Template.EffectTargetType.Both:
		Source.damage_indicator.AddEffect(Template)

	if Target != null:
		if Template.AffectedTargets == Template.EffectTargetType.Targets || Template.AffectedTargets == Template.EffectTargetType.Both:
			Target.damage_indicator.AddEffect(Template)
	pass
