extends PlayerControllerState
class_name EndGameControllerState


func _Enter(_playerController : PlayerController, _data):
	super(_playerController, _data)
	ctrl.BlockMovementInput = true
	ctrl.reticle.visible = false
	pass


func ShowInspectUI():
	return false

func CanShowThreat():
	return false

func ToString():
	return "EndGameControllerState"
