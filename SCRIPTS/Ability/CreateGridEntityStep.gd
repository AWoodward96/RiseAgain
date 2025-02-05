extends ActionStep
class_name CreateGridEntityStep

@export var GridEntityPrefab : PackedScene

func Enter(_actionLog : ActionLog):
	super(_actionLog)

	# Summon the entity on the action origin tile and rotate it
	var gridentity = GridEntityPrefab.instantiate() as GridEntityBase
	if gridentity == null:
		return

	if gridentity.get("direction") != null:
		gridentity.direction = _actionLog.actionDirection

	gridentity.Spawn(Map.Current, _actionLog.actionOriginTile, source, ability, source.UnitAllegiance)
	Map.Current.AddGridEntity(gridentity)

#func Execute(_delta):
	#return true

#func GetResult(_actionLog : ActionLog, _specificTile : TileTargetedData):
	#pass
