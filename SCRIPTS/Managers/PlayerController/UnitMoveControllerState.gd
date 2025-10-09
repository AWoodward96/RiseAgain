extends PlayerControllerState
class_name UnitMoveControllerState

var walkedPath : Array[Tile]
var prevTile : Tile
var movementSelected : bool

func _Enter(_ctrl : PlayerController, data):
	super(_ctrl, data)

	walkedPath = currentGrid.GetTilePath(ctrl.selectedUnit, ctrl.selectedUnit.CurrentTile, ctrl.CurrentTile)
	prevTile = ctrl.CurrentTile
	ctrl.UnitMovedIntoShroud = false
	StartMovementTracker()
	currentGrid.ShowUnitActions(ctrl.selectedUnit)
	UpdateTracker()
	ctrl.selectedUnit.PlayAnimation(UnitSettingsTemplate.ANIM_SELECTED)

func _Execute(_delta):
	if UpdateInput(_delta):
		UpdateTracker()

	ctrl.UpdateCameraPosition()

	if InputManager.selectDown && !CutsceneManager.BlockSelectInput:
		InputManager.ReleaseSelect()
		var tile = currentGrid.GetTile(ctrl.ConvertGlobalPositionToGridPosition())

		if ctrl.forcedTileSelection != null && tile != ctrl.forcedTileSelection:
			return

		if ctrl.selectedUnit != null && ctrl.selectedUnit.UnitAllegiance == GameSettingsTemplate.TeamID.ALLY && tile.CanMove && (tile.Occupant == null || tile.Occupant == ctrl.selectedUnit || (tile.Occupant != null && tile.Occupant.ShroudedFromPlayer)):
			ctrl.selectedUnit.PendingMove = walkedPath.size() > 1	# the path starts with the units current tile - so check above 1
			ctrl.selectedUnit.MoveCharacterToNode(MovementData.Construct(walkedPath, tile))
			EndMovementTracker()
			movementSelected = true
			ctrl.BlockMovementInput = true
			ctrl.OnTileSelected.emit(tile)
			ctrl.reticleSelectSound.play()
			AudioManager.RaiseIntensity(2)


	if InputManager.cancelDown:
		if CutsceneManager.BlockCancelInput || ctrl.UnitMovedIntoShroud || !ctrl.selectedUnit.CanMove:
			return

		if movementSelected:
			movementSelected = false
			ctrl.BlockMovementInput = false
			ctrl.selectedUnit.PendingMove = false

			ctrl.selectedUnit.StopCharacterMovement()
			currentGrid.SetUnitGridPosition(ctrl.selectedUnit, ctrl.selectedUnit.TurnStartTile.Position, true)
			ctrl.selectedUnit.visual.UpdateShrouded()

			StartMovementTracker()
			currentGrid.ShowUnitActions(ctrl.selectedUnit)
			UpdateTracker()
			ctrl.selectedUnit.PlayAnimation(UnitSettingsTemplate.ANIM_SELECTED)
		else:
			EndMovementTracker()
			currentGrid.ClearActions()
			ctrl.ForceReticlePosition(ctrl.selectedUnit.GridPosition)
			ctrl.selectedUnit.PlayAnimation(UnitSettingsTemplate.ANIM_IDLE)
			ctrl.selectedUnit = null
			ctrl.ChangeControllerState(SelectionControllerState.new(), null)
			walkedPath.clear()
		ctrl.reticleCancelSound.play()

func UpdateTracker():
	if currentMap != null && ctrl.movement_tracker.visible && ctrl.CurrentTile != null:
		if ctrl.CurrentTile.CanMove:
			var unitMovement = ctrl.selectedUnit.GetUnitMovement()
			if walkedPath.size() - 1 == unitMovement:
				walkedPath = currentGrid.GetTilePath(ctrl.selectedUnit, ctrl.selectedUnit.CurrentTile, ctrl.CurrentTile)
			else:
				if walkedPath.size() > 1 && walkedPath[walkedPath.size() - 2] == ctrl.CurrentTile:
					walkedPath.remove_at(walkedPath.size() - 1)
				else:
					if movementThisFrame.length() <= 1 && prevTile.CanMove && !walkedPath.has(ctrl.CurrentTile):
						walkedPath.append(ctrl.CurrentTile)
					else:
						walkedPath = currentGrid.GetTilePath(ctrl.selectedUnit, ctrl.selectedUnit.CurrentTile, ctrl.CurrentTile)

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
