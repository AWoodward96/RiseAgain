extends GridEntityBase
class_name GEWalkablePlatform

@export var shapedTiles : TargetingShapeBase
@export var orientation : GameSettingsTemplate.Direction
@export var health : int = -1 # If health is -1 then it is indistructable
@export var visual : Node2D

var tiles : Array[TileTargetedData]


func Spawn(_map : Map, _origin : Tile, _source : UnitInstance, _ability : Ability, _allegience : GameSettingsTemplate.TeamID):
	super(_map, _origin, _source, _ability, _allegience)

	UpdateOrientation()
	UpdatePositionOnGrid()

func UpdateOrientation():
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


func UpdatePositionOnGrid():
	if shapedTiles == null:
		push_error("Grid Entity Platform is missing their shaped tiles. " + self.name)
		return

	var newTiles = shapedTiles.GetTargetedTilesFromDirection(Source, null, CurrentMap.grid, Origin, orientation)
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


func ToJSON():
	var dict = super()
	dict["orientation"] = orientation
	dict["type"] = "GEWalkablePlatform"
	return dict

func InitFromJSON(_dict : Dictionary):
	super(_dict)
	position = Origin.GlobalPosition
	orientation = _dict["orientation"]
	UpdateOrientation()
	UpdatePositionOnGrid()
	pass
