extends PlayerControllerState
class_name ContextControllerState

func _Enter(_ctrl : PlayerController, data):
	super(_ctrl, data)
	reticle.visible = false

	ctrl.UpdateContextUI()
	ctrl.combatHUD.ShowNoTargets(false)
	ctrl.combatHUD.ShowContext()
	currentGrid.ClearActions()

func UpdateInput(_delta):
	# don't accept inputs heres
	if InputManager.cancelDown:
		if CutsceneManager.BlockCancelInput:
			return

		if ctrl.unitInventoryOpen:
			return

		ctrl.selectedUnit.StopCharacterMovement()

		# Done in this order, so that the Reticle is where the unit was hovering before cancel was called
		ctrl.ForceReticlePosition(ctrl.selectedUnit.GridPosition)
		currentGrid.SetUnitGridPosition(ctrl.selectedUnit, ctrl.selectedUnit.TurnStartTile.Position, true)

		if ctrl.selectedUnit.CanMove:
			ctrl.EnterUnitMovementState()
		else:
			ctrl.EnterSelectionState()
		ctrl.reticleCancelSound.play()
	pass

func _Exit():
	ctrl.combatHUD.HideContext()
	reticle.visible = true
	ctrl.BlockMovementInput = false


func ToString():
	return "ContextControllerState"

func ShowInspectUI():
	return false
