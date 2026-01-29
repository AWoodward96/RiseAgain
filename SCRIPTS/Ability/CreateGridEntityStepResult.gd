extends ActionStepResult
class_name CreateGridEntityStepResult

var prefab : PackedScene
#var playerController : PlayerController


## No longer necessary because we make a grid entity in the targeting preview itself
#func PreviewResult(_map : Map):
	## First let's implement a preview in general
	#playerController = _map.playercontroller
	#playerController.PreviewGridEntity(prefab)
	#playerController.grid_entity_preview_sprite.position = TileTargetData.Tile.GlobalPosition
	#pass
#
#func CancelPreview():
	#if playerController != null:
		#playerController.CancelGridEntityPreview()
	#pass
