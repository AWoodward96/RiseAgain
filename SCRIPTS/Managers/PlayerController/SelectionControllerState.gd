extends PlayerControllerState
class_name SelectionControllerState

func _Enter(_playerController : PlayerController, _data):
	super(_playerController, _data)

	if CutsceneManager.active_cutscene == null:
		ctrl.reticle.visible = true
	ctrl.BlockMovementInput = false
	pass


func _Execute(_delta):
	super(_delta)

	if InputManager.selectDown:
		var isAllyTurn = currentMap.currentTurn == GameSettingsTemplate.TeamID.ALLY

		var tile = currentGrid.GetTile(ConvertGlobalPositionToGridPosition())
		if ctrl.forcedTileSelection != null && tile != ctrl.forcedTileSelection:
			return

		if tile.Occupant != null:
			ctrl.selectedUnit = tile.Occupant as UnitInstance
			#print("Okay am I crazy?????" + str(ctrl.selectedUnit) + " VS " + str(tile.Occupant))

			if ctrl.selectedUnit.Activated:
				if ctrl.selectedUnit.UnitAllegiance == GameSettingsTemplate.TeamID.ALLY && isAllyTurn:
					# This blocks the ability to cheese units that are mid-action
					if ctrl.selectedUnit.IsStackFree:
						if ctrl.selectedUnit.CanMove:
							ctrl.EnterUnitMovementState()
						else:
							ctrl.EnterContextMenuState()
				else:
					currentGrid.ShowUnitActions(tile.Occupant)
		else:
			ctrl.EnterGlobalContextState()
		ctrl.OnTileSelected.emit(tile)

	if InputManager.cancelDown:
		currentGrid.ClearActions()


func ToString():
	return "SelectionControllerState"

func ShowObjective():
	return true
