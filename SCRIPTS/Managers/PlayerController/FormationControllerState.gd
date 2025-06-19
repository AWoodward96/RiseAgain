extends PlayerControllerState
class_name FormationControllerState

var formationUI


func _Enter(_ctrl : PlayerController, data):
	super(_ctrl, data)
	formationUI = UIManager.AlphaFormationUI.instantiate()
	formationUI.Initialize(ctrl, currentMap)
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
		if ctrl.selectedUnit == null:
			if tile.Occupant != null && currentMap.startingPositions.has(tile.Position):
				if tile.Occupant.UnitAllegiance == GameSettingsTemplate.TeamID.ALLY:
					ctrl.selectedUnit = tile.Occupant
					formationUI.ShowSwapWithPanel(true)
					currentGrid.ClearActions()
				else:
					ctrl.selectedUnit = tile.Occupant
					currentGrid.ShowUnitActions(tile.Occupant)
			else:
				currentGrid.ClearActions()
		else:
			if ctrl.selectedUnit.UnitAllegiance == GameSettingsTemplate.TeamID.ALLY:
				if currentMap.startingPositions.has(tile.Position):
					if tile.Occupant != null && tile.Occupant.UnitAllegiance == GameSettingsTemplate.TeamID.ALLY:
						currentGrid.SwapUnitPositions(ctrl.selectedUnit, tile.Occupant)
					else:
						currentGrid.SetUnitGridPosition(ctrl.selectedUnit, tile.Position, true)

			ctrl.ClearSelectionData()
			formationUI.ShowSwapWithPanel(false)

		ctrl.reticleSelectSound.play()

	if InputManager.cancelDown:
		if ctrl.selectedUnit == null:
			formationUI.SetFormationMode(false)

		ctrl.ClearSelectionData()
		formationUI.ShowSwapWithPanel(false)
		ctrl.reticleCancelSound.play()

func ToString():
	return "FormationControllerState"
