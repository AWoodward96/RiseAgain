extends PlayerControllerState
class_name VictoryControllerState


func _Enter(_playerController : PlayerController, _data):
	super(_playerController, _data)
	ctrl.BlockMovementInput = true
	ctrl.reticle.visible = false
	pass
