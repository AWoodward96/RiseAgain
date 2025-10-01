extends TargetingShapeBase
class_name TargetingShapeStats

@export var stat : StatTemplate
@export var statsShapes : Array[ThresholdTargetingShape]

func GetTileData(_unit : UnitInstance, _ability : Ability, _grid : Grid, _originTile : Tile, _atRange : int):
	var res = GetShapeFromStat(_unit.GetWorkingStat(stat))
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
			returnedTileData.append(tileData)

	return returnedTileData

func GetCoords(_unit : UnitInstance, _ability : Ability, _range : int):
	var res = GetShapeFromStat(_unit.GetWorkingStat(stat))
	if res == null:
		return []
	return res.TileCoordinates

func GetSpecificData(_index : int, _unit : UnitInstance, _ability : Ability, _range : int):
	var res = GetShapeFromStat(_unit.GetWorkingStat(stat))
	if res == null:
		return null

	return res[_index]

func GetShapeFromStat(_statVal : int):
	var res : ThresholdTargetingShape
	for l in statsShapes:
		if l.Threshold <= _statVal:
			res = l
		else:
			return res
	return res
