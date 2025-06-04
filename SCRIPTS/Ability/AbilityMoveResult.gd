extends ActionStepResult
class_name AbilityMoveResult

var unitUsable : UnitUsable
var shapedDirection : GameSettingsTemplate.Direction
var ctrl : PlayerController
var resultingTile : Tile

func PreviewResult(_map : Map):
	ctrl = _map.playercontroller
	if ctrl == null:
		return

	var unitMovement = unitUsable.MovementData.PreviewMove(_map.grid, Source, Source.CurrentTile, TileTargetData.Tile, shapedDirection)
	if unitMovement.size() > 0:
		ctrl.movement_tracker.visible = true
		ctrl.movement_preview_sprite.visible = true

		var offset = Vector2(_map.TileSize / 2, _map.TileSize / 2)
		ctrl.movement_tracker.clear_points()
		for tile : Tile in unitMovement:
			ctrl.movement_tracker.points.append(tile.GlobalPosition + offset)
		ctrl.movement_preview_sprite.texture = Source.Template.icon
		ctrl.movement_preview_sprite.position = unitMovement[unitMovement.size() - 1].GlobalPosition + offset
		resultingTile = unitMovement[unitMovement.size()-1]
	else:
		ctrl.movement_tracker.visible = false
		ctrl.movement_preview_sprite.visible = false
		resultingTile = null

	pass

func Validate():
	if resultingTile != null:
		return resultingTile.Occupant == null || (resultingTile.Occupant != null && resultingTile.Occupant == Source)
	else:
		return false

func CancelPreview():
	if ctrl != null:
		ctrl.movement_preview_sprite.visible = false
		ctrl.movement_tracker.visible = false
	pass
