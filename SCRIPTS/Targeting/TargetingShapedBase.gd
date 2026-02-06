extends TargetingDataBase
### Targeting Shaped Base
## For any targeting class that has a shape in it, such as Shaped Free or Shaped Directional
class_name TargetingShapedBase

@export_category("Shaped Data")
@export_file("*.tres") var shapePrefabRef : String
@export var canRotate : bool = false

# This should only be used in shaped directional, but thanks to inherritence it's gotta be here
@export var stopShapeOnWall : bool = false

# untyped intentionally so there's no inherritance bullshit
var shapedTiles

func BeginTargeting(_log : ActionLog, _ctrl : PlayerController):
	super(_log, _ctrl)
	shapedTiles = load(shapePrefabRef)


func GetAffectedTiles(_unitInstance : UnitInstance, _targetedTile : Tile, _atRange : int = 0, _atRotation : GameSettingsTemplate.Direction = GameSettingsTemplate.Direction.Up):
	if shapedTiles == null:
		return [_targetedTile.AsTargetData()]

	var affectedTiles = shapedTiles.GetTargetedTilesFromDirection(_unitInstance, ability, currentGrid, _targetedTile, _atRotation, _atRange, stopShapeOnWall)
	affectedTiles = FilterAffectedTiles(affectedTiles)
	return affectedTiles
