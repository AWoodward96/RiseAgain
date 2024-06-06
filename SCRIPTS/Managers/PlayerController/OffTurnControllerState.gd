extends PlayerControllerState
class_name OffTurnControllerState

# ------------------------------
# This controller state is for any time it is NOT the Players turn
# The reticle should be invisible, or locked, and the camera should be focused on what is occuring in the map
# ------------------------------
func _Enter(_ctrl : PlayerController, data):
	super(_ctrl, data)
	reticle.visible = false
	ctrl.BlockMovementInput = true

func _Execute(_delta):
	super(_delta)

	ctrl.UpdateCameraPosition()
	var combatState = currentMap.MapState as CombatState
	if combatState != null:
		if combatState.currentUnitsTurn != null:
			ctrl.ForceReticlePosition(combatState.currentUnitsTurn.CurrentTile.Position)
	pass

func ToString():
	return "OffTurnControllerState"

func ShowInspectUI():
	return false
