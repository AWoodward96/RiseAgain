extends TargetingShapeBase
class_name TargetingShape

@export var TileCoordinates : Array[Vector2i]

func GetTiles(_unit : UnitInstance,  _grid : Grid, _originTile : Tile):
	var returnTiles : Array[Tile]
	for coord in TileCoordinates:
		var newPos = _originTile.Position + coord
		var tile = _grid.GetTile(newPos)
		if tile != null:
			returnTiles.append(tile)
	return returnTiles

func GetCoords(_unit : UnitInstance,  _grid : Grid, _originTile : Tile):
	return TileCoordinates
