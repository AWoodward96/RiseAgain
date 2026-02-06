extends ActionStepResult
class_name ApplyEffectResult

var Template : CombatEffectTemplate
var affectedIndicators : Array[DamageIndicator]

func PreviewResult(_map : Map):
	if Target != null:
		Target.damageIndicator.AddEffect(Template)
	pass
