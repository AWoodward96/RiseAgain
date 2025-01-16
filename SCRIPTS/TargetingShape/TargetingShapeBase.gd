extends Resource
class_name TargetingShapeBase


func GetTileData(_unit : UnitInstance,  _grid : Grid, _originTile : Tile):
	# Should return an array of TileTargetData
	pass

func GetCoords(_unit : UnitInstance):
	pass

func GetSpecificData(_index : int, _unit : UnitInstance):
	pass

func GetTargetedTilesFromDirection(_sourceUnit : UnitInstance, _grid : Grid, _origin : Tile, _direction : GameSettingsTemplate.Direction, _stopShapeOnWall : bool = false, _isGlobalAttack : bool = false, _isAffectedBySourceSize : bool = true):
	var retArray : Array[TileTargetedData]
	var index = 0
	for shapedTile in GetCoords(_sourceUnit):
		if shapedTile == null:
			continue

		var specificData = GetSpecificData(index, _sourceUnit)
		var tileData = TileTargetedData.new()
		var pos = shapedTile.Position as Vector2
		pos = pos.rotated(deg_to_rad(90 * _direction))

		# Take note of the bullshit you have to do here. Casting directly from a Vector2 to Vector2i ...
		# ... somehow manages to lose values, even if the Vector2 is 100% a Vector2i ...
		# ... the snapped method manages to make it so that it recognizes that 1 and -1 are in fact ints and not 0 value
		var vector2i = Vector2i(pos.snapped(Vector2.ONE))

		var originPosition = _origin.Position
		if _sourceUnit != null:
			if _sourceUnit.Template.GridSize != 1 && !_isGlobalAttack && _isAffectedBySourceSize:
				originPosition = GameSettingsTemplate.GetOriginPositionFromDirection(_sourceUnit.Template.GridSize, originPosition, _direction)
				pass

		var relativePosition = originPosition + vector2i


		var specificDataAsComplex = specificData as Vector2iMultComplex

		var tile = _grid.GetTile(relativePosition) as Tile
		if tile != null:
			tileData.Tile = tile
			tileData.AOEMultiplier = shapedTile.Multiplier
			tileData.CritModifier = shapedTile.get("CritModifier") if shapedTile.get("CritModifier") != null else 0
			tileData.AccuracyModifier = shapedTile.get("AccuracyModifier") if shapedTile.get("AccuracyModifier") != null else 0

			if tile.IsWall && _stopShapeOnWall:
				return retArray

			if specificDataAsComplex != null:
				if specificDataAsComplex.pushInfo != null:
					var info = specificDataAsComplex.pushInfo
					tileData.pushAmount = info.pushAmount
					tileData.carryLimit = info.carryLimit
					tileData.pushCanDamageUser = info.canDamageUser
					if info.overrideActionDirection:
						tileData.pushDirection = info.pushDirectionOverride
					else:
						tileData.pushDirection = _direction
					_grid.PushCast(tileData)

			retArray.append(tileData)
		index += 1
	return retArray
