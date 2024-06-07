extends PlayerControllerState
class_name SelectionControllerState

func _Enter(_playerController : PlayerController, _data):
	super(_playerController, _data)

	ctrl.reticle.visible = true
	ctrl.BlockMovementInput = false
	pass


func _Execute(_delta):
	super(_delta)

	if InputManager.selectDown:
		var isAllyTurn = currentMap.currentTurn == GameSettings.TeamID.ALLY

		var tile = currentGrid.GetTile(ConvertGlobalPositionToGridPosition())
		if tile.Occupant != null :
			selectedUnit = tile.Occupant

			if selectedUnit.Activated:
				if selectedUnit.UnitAllegiance == GameSettings.TeamID.ALLY && isAllyTurn:
					ctrl.EnterUnitMovementState()
				else:
					currentGrid.ShowUnitActions(tile.Occupant)

	if InputManager.cancelDown:
		currentGrid.ClearActions()


func ToString():
	return "SelectionControllerState"
