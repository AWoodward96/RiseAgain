extends ActionStep
class_name ApplyEffectStep

@export var CombatEffect : CombatEffectTemplate

func Enter(_actionLog : ActionLog):
	super(_actionLog)
	if CombatEffect == null:
		return true

	if CombatEffect.AffectedTargets == CombatEffect.EffectTargetType.Source || CombatEffect.AffectedTargets == CombatEffect.EffectTargetType.Both:
		var effect = CombatEffectInstance.Create(source, source, CombatEffect, _actionLog)
		source.AddCombatEffect(effect)

	if CombatEffect.AffectedTargets == CombatEffect.EffectTargetType.Targets || CombatEffect.AffectedTargets == CombatEffect.EffectTargetType.Both:
		for results in _actionLog.actionResults:
			var effect = CombatEffectInstance.Create(source, results.Target, CombatEffect, _actionLog)
			results.Target.AddCombatEffect(effect)

	return true
