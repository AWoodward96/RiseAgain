extends TargetingShapeBase
class_name TargetingShapeLevel

@export var leveledShapes : Array[ThresholdTargetingShape]

func GetTileData(_unit : UnitInstance, _ability : Ability, _grid : Grid, _originTile : Tile, _atRange : int):
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
			tileData.Ignite = coord.get("Ignite") if coord.get("Ignite") != null else 0
			tileData.HitsEnvironment = coord.get("HitsEnvironment") if coord.get("HitsEnvironment") != null else true
			returnedTileData.append(tileData)

	return returnedTileData

func GetCoords(_unit : UnitInstance, _ability : Ability, _atRange : int):
	var res = GetShapeFromLevel(_unit)
	if res == null:
		return []
	return res.TileCoordinates

func GetSpecificData(_index : int, _unit : UnitInstance, _ability : Ability, _atRange : int):
	var res = GetShapeFromLevel(_unit)
	if res == null:
		return null

	return res[_index]

func GetShapeFromLevel(_unit : UnitInstance):
	var res : ThresholdTargetingShape
	for l in leveledShapes:
		if l.Threshold <= _unit.Level:
			res = l
		else:
			return res
	return res
