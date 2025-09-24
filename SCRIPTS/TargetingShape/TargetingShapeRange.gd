extends TargetingShapeBase
class_name TargetingShapeRange

@export var rangedShape : Array[ThresholdTargetingShape]

func GetTileData(_unit : UnitInstance, _ability : Ability, _grid : Grid, _originTile : Tile, _atRange : int):
	var res = GetShapeFromRange(_atRange)
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
	var res = GetShapeFromRange(_atRange)
	if res == null:
		return []
	return res.TileCoordinates

func GetSpecificData(_index : int, _unit : UnitInstance, _ability : Ability, _range : int):
	var res = GetShapeFromRange(_range)
	if res == null:
		return null

	return res.TileCoordinates[_index]

func GetShapeFromRange(_atRange : int):
	for l : ThresholdTargetingShape in rangedShape:
		if l.Threshold == _atRange:
			return l
	return null
