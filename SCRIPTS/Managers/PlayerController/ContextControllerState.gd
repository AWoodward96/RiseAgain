extends PlayerControllerState
class_name ContextControllerState

func _Enter(_ctrl : PlayerController, data):
	super(_ctrl, data)
	reticle.visible = false
	ctrl.combatHUD.ShowNoTargets(false)
	ctrl.combatHUD.ShowContext(selectedUnit)
	currentGrid.ClearActions()

func UpdateInput(_delta):
	# don't accept inputs here
	if InputManager.cancelDown:
		if ctrl.unitInventoryOpen:
			return

		selectedUnit.StopCharacterMovement()

		# Done in this order, so that the Reticle is where the unit was hovering before cancel was called
		ctrl.ForceReticlePosition(selectedUnit.GridPosition)
		currentGrid.SetUnitGridPosition(selectedUnit,selectedUnit.TurnStartTile.Position, true)

		ctrl.EnterUnitMovementState()
	pass

func _Exit():
	ctrl.combatHUD.HideContext()
	reticle.visible = true
	ctrl.BlockMovementInput = false

func ToString():
	return "ContextControllerState"

func ShowInspectUI():
	return false
