extends ActionStep
class_name ApplyEffectStep

@export var CombatEffect : CombatEffectTemplate

func Enter(_actionLog : ActionLog):
	super(_actionLog)
	if CombatEffect == null:
		return true

	# This step doesn't use the apply effect result for it's logic - it does it all on it's own.
	# The effect result is just there to preview what the ability is doing, and when
	if CombatEffect.AffectedTargets == CombatEffect.EffectTargetType.Source || CombatEffect.AffectedTargets == CombatEffect.EffectTargetType.Both:
		var effect = CombatEffectInstance.Create(source, source, CombatEffect, _actionLog)
		source.AddCombatEffect(effect)

	if CombatEffect.AffectedTargets == CombatEffect.EffectTargetType.Targets || CombatEffect.AffectedTargets == CombatEffect.EffectTargetType.Both:
		var stepResults = _actionLog.GetResultsFromActionIndex(_actionLog.actionStackIndex)
		for results in stepResults:
			if results.Target == null:
				continue
			var effect = CombatEffectInstance.Create(source, results.Target, CombatEffect, _actionLog)
			results.Target.AddCombatEffect(effect)

	return true


func GetResult(_actionLog : ActionLog, _specificTile : TileTargetedData):
	var result = ApplyEffectResult.new()
	result.Template = CombatEffect
	result.TileTargetData = _specificTile
	result.Target = _specificTile.Tile.Occupant
	result.Source = _actionLog.source
	return result
