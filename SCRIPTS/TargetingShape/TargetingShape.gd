extends TargetingShapeBase
class_name TargetingShape

@export var TileCoordinates : Array[Vector2iMult]

func GetTileData(_unit : UnitInstance,  _grid : Grid, _originTile : Tile):
	var returnTileData : Array[Tile]
	for coord in TileCoordinates:
		var tileData = TileTargetedData.new()
		var newPos = _originTile.Position + coord.Position
		var tile = _grid.GetTile(newPos)
		if tile != null:
			tileData.Tile = tile
			tileData.AOEMultiplier = coord.Multiplier
			returnTileData.append(tileData)
	return returnTileData

func GetCoords(_unit : UnitInstance,  _grid : Grid, _originTile : Tile):
	return TileCoordinates
