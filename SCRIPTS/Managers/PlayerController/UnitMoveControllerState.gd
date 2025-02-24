extends PlayerControllerState
class_name UnitMoveControllerState

var walkedPath : Array[Tile]
var prevTile : Tile
var movementSelected : bool

func _Enter(_ctrl : PlayerController, data):
	super(_ctrl, data)

	walkedPath = currentGrid.GetTilePath(selectedUnit, selectedUnit.CurrentTile, ctrl.CurrentTile)
	prevTile = ctrl.CurrentTile
	StartMovementTracker()
	currentGrid.ShowUnitActions(selectedUnit)
	UpdateTracker()
	selectedUnit.PlayAnimation(UnitSettingsTemplate.ANIM_SELECTED)

func _Execute(_delta):
	if UpdateInput(_delta):
		UpdateTracker()

	ctrl.UpdateCameraPosition()

	if InputManager.selectDown:
		var tile = currentGrid.GetTile(ctrl.ConvertGlobalPositionToGridPosition())
		if selectedUnit != null && selectedUnit.UnitAllegiance == GameSettingsTemplate.TeamID.ALLY && tile.CanMove && (tile.Occupant == null || tile.Occupant == selectedUnit):
			selectedUnit.PendingMove = walkedPath.size() > 1	# the path starts with the units current tile - so check above 1
			selectedUnit.MoveCharacterToNode(walkedPath, tile)
			EndMovementTracker()
			movementSelected = true
			ctrl.BlockMovementInput = true


	if InputManager.cancelDown:
		if movementSelected:
			movementSelected = false
			ctrl.BlockMovementInput = false
			selectedUnit.PendingMove = false

			selectedUnit.StopCharacterMovement()
			currentGrid.SetUnitGridPosition(selectedUnit, selectedUnit.TurnStartTile.Position, true)

			StartMovementTracker()
			currentGrid.ShowUnitActions(selectedUnit)
			UpdateTracker()
			selectedUnit.PlayAnimation(UnitSettingsTemplate.ANIM_SELECTED)
		else:
			EndMovementTracker()
			currentGrid.ClearActions()
			ctrl.ForceReticlePosition(selectedUnit.GridPosition)
			selectedUnit.PlayAnimation(UnitSettingsTemplate.ANIM_IDLE)
			selectedUnit = null
			ctrl.ChangeControllerState(SelectionControllerState.new(), null)
			walkedPath.clear()

func UpdateTracker():
	if currentMap != null && ctrl.movement_tracker.visible && ctrl.CurrentTile != null:
		if ctrl.CurrentTile.CanMove:
			var unitMovement = selectedUnit.GetUnitMovement()
			if walkedPath.size() - 1 == unitMovement:
				walkedPath = currentGrid.GetTilePath(selectedUnit, selectedUnit.CurrentTile, ctrl.CurrentTile)
			else:
				if walkedPath.size() > 1 && walkedPath[walkedPath.size() - 2] == ctrl.CurrentTile:
					walkedPath.remove_at(walkedPath.size() - 1)
				else:
					if movementThisFrame.length() <= 1 && prevTile.CanMove && !walkedPath.has(ctrl.CurrentTile):
						walkedPath.append(ctrl.CurrentTile)
					else:
						walkedPath = currentGrid.GetTilePath(selectedUnit, selectedUnit.CurrentTile, ctrl.CurrentTile)

			ctrl.movement_tracker.clear_points()
			for p in walkedPath:
				# Halfsize because otherwise the line's in the top left corner of the tile
				ctrl.movement_tracker.add_point(p.GlobalPosition + Vector2(ctrl.tileHalfSize, ctrl.tileHalfSize))
	prevTile = ctrl.CurrentTile


func StartMovementTracker():
	ctrl.movement_tracker.visible = true
	ctrl.movement_tracker.clear_points()

func EndMovementTracker():
	ctrl.movement_tracker.visible = false
	currentGrid.ClearActions()

func ToString():
	return "UnitMoveControllerState"

func ShowInspectUI():
	return false
