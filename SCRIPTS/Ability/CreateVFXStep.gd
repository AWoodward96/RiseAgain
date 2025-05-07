extends ActionStep
class_name CreateVFXStep

@export var VFXPrefab : PackedScene


func Enter(_actionLog : ActionLog):
	log = _actionLog

	var vfx = VFXPrefab.instantiate()
	_actionLog.grid.map.add_child(vfx)
	vfx.position = _actionLog.actionOriginTile.GlobalPosition
	return true
