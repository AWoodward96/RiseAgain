extends TargetingShapeBase
class_name TargetingShapeLevel

@export var leveledShapes : Array[LeveledTargetingShape]

func GetTileData(_unit : UnitInstance,  _grid : Grid, _originTile : Tile):
	var res = GetShapeFromLevel(_unit)
	if res == null:
		return []

	var returnedTileData : Array[TileTargetedData]
	for coord in res.TileCoordinates:
		var tileData = TileTargetedData.new()
		var newPos = _originTile.Position + coord.Position
		var tile = _grid.GetTile(newPos)
		if tile != null:
			tileData.Tile = tile
			tileData.AOEMultiplier = coord.Multiplier
			tileData.CritModifier = coord.get("CritModifier") if coord.get("CritModifier") != null else 0
			tileData.AccuracyModifier = coord.get("AccuracyModifier") if coord.get("AccuracyModifier") != null else 0
			returnedTileData.append(tileData)

	return returnedTileData

func GetCoords(_unit : UnitInstance):
	var res = GetShapeFromLevel(_unit)
	if res == null:
		return []
	return res.TileCoordinates

func GetSpecificData(_index : int, _unit : UnitInstance):
	var res = GetShapeFromLevel(_unit)
	if res == null:
		return null

	return res[_index]

func GetShapeFromLevel(_unit : UnitInstance):
	var res : LeveledTargetingShape
	for l in leveledShapes:
		if l.LevelTheshold <= _unit.Level:
			res = l
		else:
			return res
	return res
