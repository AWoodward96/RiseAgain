extends ActionStepResult
class_name ApplyEffectResult

var Template : CombatEffectTemplate


func PreviewResult(_map : Map):
	if Template.AffectedTargets == Template.EEffectTargetType.Source || Template.AffectedTargets == Template.EEffectTargetType.Both:
		Source.damage_indicator.AddEffect(Template)

	if Target != null:
		if Template.AffectedTargets == Template.EEffectTargetType.Targets || Template.AffectedTargets == Template.EEffectTargetType.Both:
			Target.damage_indicator.AddEffect(Template)
	pass
