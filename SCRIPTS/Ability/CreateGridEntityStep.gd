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

func GetResult(_actionLog : ActionLog, _specificTile : TileTargetedData):
	var preview = CreateGridEntityStepResult.new()
	preview.TileTargetData = _specificTile
	preview.Source = _actionLog.source
	preview.prefab = GridEntityPrefab
	return preview
