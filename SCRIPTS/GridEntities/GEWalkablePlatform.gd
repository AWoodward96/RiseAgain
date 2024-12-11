extends GridEntityBase
class_name GEWalkablePlatform

@export var shapedTiles : TargetingShapeBase
@export var orientation : GameSettingsTemplate.Direction
@export var health : int = -1 # If health is -1 then it is indistructable
@export var visual : Node2D

var tiles : Array[TileTargetedData]


func Spawn(_map : Map, _origin : Tile, _source : UnitInstance, _allegience : GameSettingsTemplate.TeamID):
	super(_map, _origin, _source, _allegience)
	if visual != null:
		visual.rotation = deg_to_rad(90 * orientation)

		match(orientation):
			0:
				visual.position = Vector2i(0, 0)
			1:
				visual.position = Vector2i(32, 0)
			2:
				visual.position = Vector2i(32, 32)
			3:
				visual.position = Vector2i(0, 32)

	UpdatePositionOnGrid()

func UpdatePositionOnGrid():
	if shapedTiles == null:
		push_error("Grid Entity Platform is missing their shaped tiles. " + self.name)
		return

	var newTiles = shapedTiles.GetTargetedTilesFromDirection(Source, CurrentMap.grid, Origin, orientation)
	for t in tiles:
		if t == null || t.Tile == null:
			continue

		t.Tile.RemoveEntity(self)

	tiles = newTiles
	for t in tiles:
		if t == null || t.Tile == null:
			continue

		t.Tile.AddEntity(self)
	pass
