extends PlayerControllerState
class_name UnitMoveControllerState


func _Enter(_ctrl : PlayerController, data):
	super(_ctrl, data)

	StartMovementTracker(selectedUnit.GridPosition)
	currentGrid.ShowUnitActions(selectedUnit)
	UpdateTracker()

func _Execute(_delta):
	if UpdateInput(_delta):
		UpdateTracker()

	ctrl.UpdateCameraPosition()

	if InputManager.selectDown:
		var tile = currentGrid.GetTile(ctrl.ConvertGlobalPositionToGridPosition())
		if selectedUnit != null && selectedUnit.UnitAllegiance == GameSettings.TeamID.ALLY && tile.CanMove:
			var path = currentGrid.Pathfinding.get_point_path(selectedUnit.GridPosition, tile.Position)
			selectedUnit.MoveCharacterToNode(path, tile)
			EndMovementTracker()
			ctrl.EnterContextMenuState()

	if InputManager.cancelDown:
		EndMovementTracker()
		currentGrid.ClearActions()
		ctrl.ForceReticlePosition(selectedUnit.GridPosition)
		selectedUnit = null
		ctrl.ChangeControllerState(SelectionControllerState.new(), null)

func UpdateTracker():
	if currentMap != null && ctrl.movement_tracker.visible && ctrl.CurrentTile != null:
		if ctrl.CurrentTile.CanMove:
			var packedPathArray = currentGrid.Pathfinding.get_point_path(selectedUnit.GridPosition, ctrl.CurrentTile.Position)
			ctrl.movement_tracker.clear_points()
			for p in packedPathArray:
				# Halfsize because otherwise the line's in the top left corner of the tile
				ctrl.movement_tracker.add_point(p + Vector2(ctrl.tileHalfSize, ctrl.tileHalfSize))

func StartMovementTracker(_origin : Vector2i):
	ctrl.movement_tracker.visible = true
	ctrl.movement_tracker.clear_points()

func EndMovementTracker():
	ctrl.movement_tracker.visible = false
	currentGrid.ClearActions()

func ToString():
	return "UnitMoveControllerState"

func ShowInspectUI():
	return false
