extends ActionStep
class_name CreateGridEntityStep

@export var GridEntityPrefab : PackedScene

func Enter(_actionLog : ActionLog):
	super(_actionLog)

	# Summon the entity on the action origin tile and rotate it
	var gridentity = GridEntityPrefab.instantiate() as GridEntityBase
	if gridentity == null:
		return

	gridentity.Spawn(Map.Current, _actionLog.actionOriginTile, source, ability, source.UnitAllegiance, _actionLog.actionDirection)
	Map.Current.AddGridEntity(gridentity)

#func Execute(_delta):
	#return true

func GetResults(_actionLog : ActionLog, _availableTiles : Array[TileTargetedData]):
	var preview = CreateGridEntityStepResult.new()
	var found = false
	for tileTargetedData in _availableTiles:
		if tileTargetedData.Tile == _actionLog.actionOriginTile:
			preview.TileTargetData = tileTargetedData
			preview.Source = _actionLog.source
			preview.prefab = GridEntityPrefab
			found = true
			break

	if !found:
		preview.TileTargetData = _actionLog.actionOriginTile.AsTargetData()
		preview.Source = _actionLog.source
		preview.prefab = GridEntityPrefab
	return [preview]
