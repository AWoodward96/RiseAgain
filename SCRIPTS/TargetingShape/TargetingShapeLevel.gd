extends TargetingShapeBase
class_name TargetingShapeLevel

@export var leveledShapes : Array[LeveledTargetingShape]

func GetTiles(_unit : UnitInstance,  _grid : Grid, _originTile : Tile):
	var res = GetShapeFromLevel(_unit)
	if res == null:
		return []

	var returnTiles : Array[Tile]
	for coord in res.TileCoordinates:
		var newPos = _originTile.Position + coord
		var tile = _grid.GetTile(newPos)
		if tile != null:
			returnTiles.append(tile)
	return returnTiles

func GetCoords(_unit : UnitInstance,  _grid : Grid, _originTile : Tile):
	var res = GetShapeFromLevel(_unit)
	if res == null:
		return []
	return res.TileCoordinates

func GetShapeFromLevel(_unit : UnitInstance):
	var res : LeveledTargetingShape
	for l in leveledShapes:
		if l.LevelTheshold <= _unit.Level:
			res = l
		else:
			return res
	return res
