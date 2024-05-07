extends PlayerControllerState
class_name SelectionControllerState


func _Execute(_delta):
	super(_delta)

	if InputManager.selectDown:
		var mapState = currentMap.MapState as CombatState
		var isAllyTurn = mapState.currentTurn == GameSettings.TeamID.ALLY

		var tile = currentGrid.GetTile(ConvertGlobalPositionToGridPosition())
		if tile.Occupant != null :
			selectedUnit = tile.Occupant

			if selectedUnit.UnitAllegiance == GameSettings.TeamID.ALLY && isAllyTurn:
				ctrl.EnterUnitMovementState()
			else:
				currentGrid.ShowUnitActions(tile.Occupant)

	if InputManager.cancelDown:
		currentGrid.ClearActions()


func ToString():
	return "SelectionControllerState"
