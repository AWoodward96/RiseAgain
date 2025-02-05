extends TargetingShapeBase
class_name TargetingShapeKills

@export var leveledShapes : Array[ThresholdTargetingShape]

func GetTileData(_unit : UnitInstance, _ability : Ability, _grid : Grid, _originTile : Tile):
	var res = GetShapeFromKills(_ability)
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

func GetCoords(_unit : UnitInstance, _ability : Ability):
	var res = GetShapeFromKills(_ability)
	if res == null:
		return []
	return res.TileCoordinates

func GetSpecificData(_index : int, _unit : UnitInstance, _ability : Ability):
	var res = GetShapeFromKills(_ability)
	if res == null:
		return null

	return res[_index]

func GetShapeFromKills(_ability : Ability):
	var kills = 0
	if _ability != null:
		kills = _ability.kills

	var res : ThresholdTargetingShape
	for l in leveledShapes:
		if l.Threshold <= kills:
			res = l
		else:
			return res
	return res
