extends ActionStep
class_name CreateVFXStep

@export var VFXPrefab : PackedScene
@export var PositionOnActionOrigin : bool = true
@export var PositionOnSource : bool


func Enter(_actionLog : ActionLog):
	log = _actionLog

	var vfx = VFXPrefab.instantiate()
	_actionLog.grid.map.add_child(vfx)
	if PositionOnActionOrigin:
		vfx.position = _actionLog.actionOriginTile.GlobalPosition
	else:
		vfx.position = log.sourceTile.GlobalPosition
	return true
