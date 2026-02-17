extends Resource
class_name TargetingShapeBase


func GetTileData(_unit : UnitInstance, _ability : Ability, _grid : Grid, _originTile : Tile, _atRange : int):
	# Should return an array of TileTargetData
	pass

func GetCoords(_unit : UnitInstance, _ability : Ability, _range : int):
	pass

func GetSpecificData(_index : int, _unit : UnitInstance, _ability : Ability, _range : int):
	pass

func GetTargetedTilesFromDirection(_sourceUnit : UnitInstance, _ability : Ability, _grid : Grid, _origin : Tile, _direction : GameSettingsTemplate.Direction, _atRange : int, _stopShapeOnWall : bool = false, _isGlobalAttack : bool = false, _isAffectedBySourceSize : bool = true):
	var retArray : Array[TileTargetedData]
	var index = 0
	var offset = GameSettingsTemplate.GetVectorFromDirection(_direction) * _atRange
	for shapedTile in GetCoords(_sourceUnit, _ability, _atRange):
		if shapedTile == null:
			continue

		var specificData = GetSpecificData(index, _sourceUnit, _ability, _atRange)
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

		var relativePosition = originPosition + vector2i + offset
		var specificDataAsComplex = specificData as Vector2iMultComplex

		var tile = _grid.GetTile(relativePosition) as Tile
		if tile != null:
			tileData.Tile = tile
			tileData.AOEMultiplier = shapedTile.Multiplier
			tileData.CritModifier = shapedTile.get("CritModifier") if shapedTile.get("CritModifier") != null else 0
			tileData.AccuracyModifier = shapedTile.get("AccuracyModifier") if shapedTile.get("AccuracyModifier") != null else 0
			tileData.Ignite = shapedTile.get("Ignite") if shapedTile.get("Ignite") != null else 0

			# Ability can be null bc of the GEWalkablePlatforms6
			if _ability != null && tileData.Ignite == 0 && _ability.UsableDamageData != null:
				tileData.Ignite = _ability.UsableDamageData.Ignite
			tileData.HitsEnvironment = shapedTile.get("HitsEnvironment") if shapedTile.get("HitsEnvironment") != null else true

			if (tile.IsWall || tile.Position.y == 0) && _stopShapeOnWall:
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
