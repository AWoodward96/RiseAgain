extends TargetingShapeBase
class_name TargetingShape

@export var TileCoordinates : Array[Vector2iMult]

func GetTileData(_unit : UnitInstance, _ability : Ability, _grid : Grid, _originTile : Tile, _atRange : int):
	var returnTileData : Array[TileTargetedData]
	for coord in TileCoordinates:
		var tileData = TileTargetedData.new()
		var newPos = _originTile.Position + coord.Position
		var tile = _grid.GetTile(newPos)
		if tile != null:
			tileData.Tile = tile
			tileData.AOEMultiplier = coord.Multiplier
			tileData.CritModifier = coord.get("CritModifier") if coord.get("CritModifier") != null else 0
			tileData.AccuracyModifier = coord.get("AccuracyModifier") if coord.get("AccuracyModifier") != null else 0
			tileData.Ignite = coord.get("Ignite") if coord.get("Ignite") != null else 0
			if tileData.Ignite == 0 && _ability.UsableDamageData != null:
				tileData.Ignite = _ability.UsableDamageData.Ignite
			tileData.HitsEnvironment = coord.get("HitsEnvironment") if coord.get("HitsEnvironment") != null else true
			returnTileData.append(tileData)
	return returnTileData

func GetCoords(_unit : UnitInstance, _ability : Ability, _range : int):
	return TileCoordinates

func GetSpecificData(_index : int, _unit : UnitInstance, _ability : Ability, _range : int):
	return TileCoordinates[_index]
