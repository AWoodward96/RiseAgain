extends ActionStepResult
class_name CreateGridEntityStepResult

var prefab : PackedScene
var playerController : PlayerController

# This isn't necessary right now, but I'm making it anyway
# I'm currently tesing the demikestrel, so when I go to implement Ice Wall this could be a thing that gets
# implemented as a preview thing, but right now the player doesn't have any skills to summon grid entiteis, so no preview is necessary
func PreviewResult(_map : Map):
	# First let's implement a preview in general
	playerController = _map.playercontroller
	playerController.PreviewGridEntity(prefab)
	playerController.grid_entity_preview_sprite.position = TileTargetData.Tile.GlobalPosition
	pass

func CancelPreview():
	if playerController != null:
		playerController.CancelGridEntityPreview()
	pass
