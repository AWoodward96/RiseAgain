extends ActionStepResult
class_name ApplyEffectResult

var Template : CombatEffectTemplate
var TrueHit : bool

func PreviewResult(_map : Map):
	if Target != null:
		Target.damageIndicator.AddEffect(Template)
		if TrueHit:
			Target.damageIndicator.trueHit = true
	pass
