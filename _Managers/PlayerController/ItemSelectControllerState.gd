extends PlayerControllerState
class_name ItemSelectControllerState


func _Enter(_ctrl : PlayerController, data):
	super(_ctrl, data)
	ctrl.combatHUD.ShowItemSelectionUI(ctrl.selectedUnit)
	ctrl.reticle.visible = false
	ctrl.BlockMovementInput = true

func UpdateInput(_delta):

	if InputManager.cancelDown:
		ctrl.EnterContextMenuState()
	pass

func ShowInspectUI():
	return false

func _Exit():
	ctrl.combatHUD.ClearItemSelectionUI()
