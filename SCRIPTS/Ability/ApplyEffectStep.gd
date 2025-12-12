extends ActionStep
class_name ApplyEffectStep

@export var CombatEffect : CombatEffectTemplate

func Enter(_actionLog : ActionLog):
	super(_actionLog)
	if CombatEffect == null:
		return true

	# This step doesn't use the apply effect result for it's logic - it does it all on it's own.
	# The effect result is just there to preview what the ability is doing, and when
	if CombatEffect.AffectedTargets == CombatEffect.EEffectTargetType.Source || CombatEffect.AffectedTargets == CombatEffect.EEffectTargetType.Both:
		var effect = CombatEffectInstance.Create(source, source, CombatEffect, _actionLog.ability, _actionLog)
		if effect != null:
			source.AddCombatEffect(effect)

	if CombatEffect.AffectedTargets == CombatEffect.EEffectTargetType.Targets || CombatEffect.AffectedTargets == CombatEffect.EEffectTargetType.Both:
		var stepResults = _actionLog.GetResultsFromActionIndex(_actionLog.actionStackIndex)
		for results in stepResults:
			if results.Target == null:
				continue

			if results.Target.IsDying || results.Target.currentHealth <= 0:
				continue

			var effect = CombatEffectInstance.Create(source, results.Target, CombatEffect, _actionLog.ability, _actionLog)
			if effect != null:
				results.Target.AddCombatEffect(effect)

	return true


func GetResults(_actionLog : ActionLog, _affectedTiles : Array[TileTargetedData]):
	var results : Array[ApplyEffectResult]

	if CombatEffect.AffectedTargets == CombatEffect.EEffectTargetType.Source || CombatEffect.AffectedTargets == CombatEffect.EEffectTargetType.Both:
		var sourceResult = ApplyEffectResult.new()
		sourceResult.Template = CombatEffect
		sourceResult.Target = _actionLog.source
		sourceResult.Source = _actionLog.source

		var sourceIndex = _affectedTiles.find_custom(func(x : TileTargetedData) : return x.Tile == _actionLog.source.CurrentTile)
		if sourceIndex != -1:
			sourceResult.TileTargetData = _affectedTiles[sourceIndex]
		else:
			sourceResult.TileTargetData = _actionLog.source.CurrentTile.AsTargetData()

		results.append(sourceResult)

	if CombatEffect.AffectedTargets == CombatEffect.EEffectTargetType.Targets || CombatEffect.AffectedTargets == CombatEffect.EEffectTargetType.Both:
		for specificTile in _affectedTiles:
			# If it's both, we don't want a duplicate entry here, so skip it if the specific tile is the source tile
			if CombatEffect.AffectedTargets == CombatEffect.EEffectTargetType.Both:
				if specificTile.Tile == _actionLog.source.CurrentTile:
					continue

			var targetsResults = ApplyEffectResult.new()
			targetsResults.Template = CombatEffect
			targetsResults.Target = specificTile.Tile.Occupant
			targetsResults.Source = _actionLog.source
			targetsResults.TileTargetData = specificTile

			results.append(targetsResults)

	return results
