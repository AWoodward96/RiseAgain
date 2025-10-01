extends ActionStepResult
class_name ApplyEffectResult

var Template : CombatEffectTemplate


func PreviewResult(_map : Map):
	if Template.AffectedTargets == Template.EEffectTargetType.Source || Template.AffectedTargets == Template.EEffectTargetType.Both:
		Source.damage_indicator.AddEffect(Template)
		Source.damage_indicator.SetHealthLevels(Source.currentHealth, Source.maxHealth)

	if Target != null:
		if Template.AffectedTargets == Template.EEffectTargetType.Targets || Template.AffectedTargets == Template.EEffectTargetType.Both:
			Target.damage_indicator.AddEffect(Template)
			Target.damage_indicator.SetHealthLevels(Target.currentHealth, Target.maxHealth)
	pass
