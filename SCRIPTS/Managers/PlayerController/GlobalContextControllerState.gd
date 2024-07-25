extends PlayerControllerState
class_name GlobalContextControllerState

func _Enter(_ctrl : PlayerController, data):
	super(_ctrl, data)
	reticle.visible = false
	ctrl.BlockMovementInput = true

	ctrl.UpdateGlobalContextUI()
	ctrl.combatHUD.ShowContext()
	currentGrid.ClearActions()

func UpdateInput(_delta):
	# don't accept inputs here
	if InputManager.cancelDown:
		ctrl.EnterSelectionState()
	pass

func _Exit():
	ctrl.combatHUD.HideContext()
	reticle.visible = true
	ctrl.BlockMovementInput = false


func ToString():
	return "GlobalContextControllerState"

func ShowInspectUI():
	return false
