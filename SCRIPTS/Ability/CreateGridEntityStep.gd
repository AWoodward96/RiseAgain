extends ActionStep
class_name CreateGridEntityStep

@export var GridEntityPrefab : PackedScene

func Enter(_actionLog : ActionLog):
	super(_actionLog)

	var results = log.GetResultsFromActionIndex(log.actionStackIndex)
	for r in results:
		if r is CreateGridEntityStepResult:
			# Summon the entity on the action origin tile and rotate it
			var gridentity = GridEntityPrefab.instantiate() as GridEntityBase
			if gridentity == null:
				return

			gridentity.Spawn(Map.Current, r.TileTargetData.Tile, source, ability, source.UnitAllegiance, _actionLog.actionDirection)
			Map.Current.AddGridEntity(gridentity)


func GetResults(_actionLog : ActionLog, _affectedTiles : Array[TileTargetedData]):
	var returnArray : Array[CreateGridEntityStepResult]
	for tileTargetedData in _affectedTiles:
		var preview = CreateGridEntityStepResult.new()
		preview.TileTargetData = tileTargetedData
		preview.Source = _actionLog.source
		returnArray.append(preview)

	return returnArray
