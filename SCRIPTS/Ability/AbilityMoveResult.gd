extends ActionStepResult
class_name AbilityMoveResult

var unitUsable : UnitUsable
var shapedDirection : GameSettingsTemplate.Direction
var ctrl : PlayerController

func PreviewResult(_map : Map):
	ctrl = _map.playercontroller
	if ctrl == null:
		return

	var unitMovement = unitUsable.MovementData.PreviewMove(_map.grid, Source, TileTargetData.Tile, shapedDirection)
	if unitMovement.size() > 0:
		ctrl.movement_tracker.visible = true
		ctrl.movement_preview_sprite.visible = true

		ctrl.movement_tracker.clear_points()
		ctrl.movement_tracker.points = unitMovement
		ctrl.movement_preview_sprite.texture = Source.Template.icon
		ctrl.movement_preview_sprite.position = unitMovement[unitMovement.size() - 1]
	else:
		ctrl.movement_tracker.visible = false
		ctrl.movement_preview_sprite.visible = false
	pass

func CancelPreview():
	if ctrl != null:
		ctrl.movement_preview_sprite.visible = false
		ctrl.movement_tracker.visible = false
	pass
