extends PlayerControllerState
class_name FormationControllerState

var formationUI


func _Enter(_ctrl : PlayerController, data):
	super(_ctrl, data)
	formationUI = GameManager.AlphaFormationUI.instantiate()
	ctrl.add_child(formationUI)
	return formationUI

func _Execute(_delta):
	# do normal movement
	super(_delta)

	if ctrl.BlockMovementInput:
		return

	# Input Selection in this scenario is specifically for formation selection
	# The Formation UI will handle the movement of the units here, so don't worry about any handling of input
	if InputManager.selectDown:
		var tile = currentGrid.GetTile(ConvertGlobalPositionToGridPosition())
		if selectedUnit == null:
			if tile.Occupant != null:
				if tile.Occupant.UnitAllegiance == GameSettings.TeamID.ALLY:
					selectedUnit = tile.Occupant
					formationUI.ShowSwapWithPanel(true)
					currentGrid.ClearActions()
				else:
					currentGrid.ShowUnitActions(tile.Occupant)
			else:
				currentGrid.ClearActions()
		else:
			if tile.Occupant != null && tile.Occupant.UnitAllegiance == GameSettings.TeamID.ALLY:
				currentGrid.SwapUnitPositions(selectedUnit, tile.Occupant)
			elif currentMap.startingPositions.has(tile.Position):
				currentGrid.SetUnitGridPosition(selectedUnit, tile.Position, true)

			selectedUnit = null
			formationUI.ShowSwapWithPanel(false)

	if InputManager.cancelDown:
		ctrl.ClearSelectionData()
		formationUI.ShowSwapWithPanel(false)

func ToString():
	return "FormationControllerState"
