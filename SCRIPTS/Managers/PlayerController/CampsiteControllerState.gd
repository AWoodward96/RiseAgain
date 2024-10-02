extends PlayerControllerState
class_name CampsiteControllerState

# Basically do nothing. The Campsite UI will handle all we care about
func _Enter(_ctrl : PlayerController, data):
	super(_ctrl, data)
	ctrl.BlockMovementInput = true
	reticle.visible = false

func ToString():
	return "CampsiteControllerState"

func ShowInspectUI():
	return false

func CanShowThreat():
	return false
