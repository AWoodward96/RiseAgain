extends PlayerControllerState
class_name SelectionControllerState

func _Enter(_playerController : PlayerController, _data):
	super(_playerController, _data)

	if !CutsceneManager.InvisibleReticle:
		ctrl.reticle.visible = true
	ctrl.BlockMovementInput = false
	pass


func _Execute(_delta):
	super(_delta)

	if InputManager.selectDown && !CutsceneManager.BlockSelectInput && currentMap.PreTurnComplete:
		var isAllyTurn = currentMap.currentTurn == GameSettingsTemplate.TeamID.ALLY

		var tile = currentGrid.GetTile(ConvertGlobalPositionToGridPosition())
		if ctrl.forcedTileSelection != null && tile != ctrl.forcedTileSelection:
			return

		if tile.Occupant != null:
			ctrl.selectedUnit = tile.Occupant as UnitInstance

			if ctrl.selectedUnit.Activated:
				if ctrl.selectedUnit.UnitAllegiance == GameSettingsTemplate.TeamID.ALLY && isAllyTurn:
					# This blocks the ability to cheese units that are mid-action
					if ctrl.selectedUnit.IsStackFree:
						InputManager.ReleaseSelect()
						if ctrl.selectedUnit.CanMove:
							ctrl.EnterUnitMovementState()
							AudioManager.RaiseIntensity(1)
						else:
							ctrl.EnterContextMenuState()
						ctrl.reticleSelectSound.play()
				else:
					if !ctrl.selectedUnit.Submerged && !ctrl.selectedUnit.ShroudedFromPlayer:
						currentGrid.ShowUnitActions(tile.Occupant)
						ctrl.reticleSelectSound.play()

		else:
			InputManager.ReleaseSelect()
			ctrl.EnterGlobalContextState()
			ctrl.reticleSelectSound.play()
		ctrl.OnTileSelected.emit(tile)

	if InputManager.cancelDown:
		if CutsceneManager.BlockCancelInput:
			return

		currentGrid.ClearActions()


func ToString():
	return "SelectionControllerState"

func ShowObjective():
	return true
