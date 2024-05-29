extends PlayerControllerState
class_name UnitStackClearControllerState

var unitToWaitOn : UnitInstance

func _Enter(_playerController : PlayerController, _data):
	super(_playerController, _data)

	unitToWaitOn = _data
	ctrl.BlockMovementInput = true
	ctrl.reticle.visible = false
	pass

func _Execute(_delta):
	if unitToWaitOn.IsStackFree:
		ctrl.EnterSelectionState()
	pass
