extends ActionStep
class_name FocusCameraStep

@export var OnActionOrigin : bool = true
@export var OnSource : bool = false
@export var OnSpecificPosition : bool = false
@export var SpecificPosition : Vector2i

@export var Instant : bool = false

var ctrl : PlayerController

func Enter(_actionLog : ActionLog):
	super(_actionLog)
	if Map.Current == null:
		return

	ctrl = Map.Current.playercontroller

	if OnActionOrigin:
		ctrl.ForceCameraPosition(log.actionOriginTile.Position, Instant)
	elif OnSource:
		ctrl.ForceCameraPosition(log.sourceTile.Position, Instant)
	elif OnSpecificPosition:
		ctrl.ForceCameraPosition(SpecificPosition, Instant)



func Execute(_delta):
	if ctrl == null:
		return true

	return ctrl.CameraMovementComplete
