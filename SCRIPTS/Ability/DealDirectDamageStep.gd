extends ActionStep
class_name DealDirectDamageStep

# Damage is always true damage - until I don't want that anymore in which case fml
# -- just use PerformCombatStep if you need stuff to not be true damage

@export var DamageAmount : int
@export var Targeting : CombatEffectTemplate.EEffectTargetType = CombatEffectTemplate.EEffectTargetType.Targets


func Enter(_actionLog : ActionLog):
	super(_actionLog)


	var results = log.GetResultsFromActionIndex(log.actionStackIndex)
	for res in results:
		if res is not DealDirectDamageResult:
			continue

		var dealDirectDamageResult = res as DealDirectDamageResult
		match Targeting:
			CombatEffectTemplate.EEffectTargetType.Source:
				if _actionLog.source != null:
					_actionLog.source.ModifyHealth(DamageAmount, dealDirectDamageResult)
			CombatEffectTemplate.EEffectTargetType.Targets:
				for targ in _actionLog.affectedTiles:
					if targ.Tile.Occupant != null:
						targ.Tile.Occupant.ModifyHealth(DamageAmount, dealDirectDamageResult)
			CombatEffectTemplate.EEffectTargetType.Both:
				if _actionLog.source != null:
					_actionLog.source.ModifyHealth(DamageAmount, dealDirectDamageResult)

				for targ in _actionLog.affectedTiles:
					if targ.Tile.Occupant != null:
						targ.Tile.Occupant.ModifyHealth(DamageAmount, dealDirectDamageResult)
	return true



func GetResult(_actionLog : ActionLog, _specificTile : TileTargetedData):
	var result = DealDirectDamageResult.new()
	result.AbilityData = _actionLog.ability
	result.TileTargetData = _specificTile
	result.Source = _actionLog.source
	result.Target = _specificTile.Tile.Occupant

	match Targeting:
		CombatEffectTemplate.EEffectTargetType.Source:
			result.SourceHealthDelta = DamageAmount
		CombatEffectTemplate.EEffectTargetType.Targets:
			result.HealthDelta = DamageAmount
		CombatEffectTemplate.EEffectTargetType.Both:
			result.SourceHealthDelta = DamageAmount
			result.HealthDelta = DamageAmount

	result.CalculateEXPGain()
	return result

func GetResults(_actionLog : ActionLog, _availableTiles : Array[TileTargetedData]):
	var returnArr : Array[DealDirectDamageResult]
	for tile in _availableTiles:
		var result = GetResult(_actionLog, tile)
		returnArr.append(result)
	return returnArr
