extends GridEntityBase
class_name GEProp

@export var shapedTiles : TargetingShapeBase

var tiles : Array[TileTargetedData]


func Spawn(_map : Map, _origin : Tile, _source : UnitInstance, _ability : Ability, _allegience : GameSettingsTemplate.TeamID):
	super(_map, _origin, _source, _ability, _allegience)
	UpdatePositionOnGrid()

func UpdatePositionOnGrid():
	if shapedTiles == null:
		push_error("Grid Entity Platform is missing their shaped tiles. " + self.name)
		return

	var newTiles = shapedTiles.GetTargetedTilesFromDirection(Source, null, CurrentMap.grid, Origin, GameSettingsTemplate.Direction.Up)
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
	dict["type"] = "GEProp"
	return dict

func InitFromJSON(_dict : Dictionary):
	super(_dict)
	position = Origin.GlobalPosition
	UpdatePositionOnGrid()
	pass
