extends Node2D
class_name SkillTargetingData

enum TargetingType { Simple, ShapedFree, ShapedDirectional, SelfOnly }
enum TargetingTeamFlag { AllyTeam, EnemyTeam, All, Empty }

@export var TeamTargeting : TargetingTeamFlag = TargetingTeamFlag.EnemyTeam

# x = min, y = max
@export var TargetRange : Vector2i = Vector2i(1, 1)
@export var Type : TargetingType
@export var CanTargetSelf : bool = false

@export var shapedTiles : TargetingShapeBase
@export var stopShapeOnWall : bool = false


func GetAdditionalTileTargets(_unit : UnitInstance, _grid : Grid, _tile : Tile):
	var addtionalTargetedTiles : Array[TileTargetedData]
	match Type:
		TargetingType.Simple:
			addtionalTargetedTiles.append(_tile.AsTargetData())
		TargetingType.ShapedFree:
			if shapedTiles != null:
				addtionalTargetedTiles.append_array(shapedTiles.GetTileData(_unit, _grid, _tile))
			addtionalTargetedTiles = FilterByTargettingFlags(_unit, addtionalTargetedTiles)
			pass
		TargetingType.ShapedDirectional:
			pass
		TargetingType.SelfOnly:
			addtionalTargetedTiles = [_unit.CurrentTile.AsTargetData()]


	return addtionalTargetedTiles

func GetAffectedTiles(_unit : UnitInstance, _grid : Grid, _tile : Tile):
	var returnThis = GetAdditionalTileTargets(_unit, _grid, _tile)
	return returnThis

func GetTilesInRange(_unit : UnitInstance, _grid : Grid, _sort : bool = true):
	var options : Array[Tile]
	if Type == TargetingType.SelfOnly:
		options = [_unit.CurrentTile]
	else:
		options = _grid.GetCharacterAttackOptions(_unit, [_unit.CurrentTile], TargetRange)

	options = FilterTilesByTargettingFlags(_unit, options)

	if options.size() > 1 && _sort:
		options.sort_custom(OrderTargets)
	return options

func GetDirectionalAttack(_unit : UnitInstance, _grid : Grid, _directionIndex : GameSettingsTemplate.Direction):
	var arr : Array[TileTargetedData]
	var unitOriginTile = _unit.CurrentTile
	if shapedTiles == null:
		return arr

	var index = 0
	for shapedTile in shapedTiles.GetCoords(_unit, _grid, unitOriginTile):
		if shapedTile == null:
			continue
		var specificData = shapedTiles.GetSpecificData(index, _unit)
		var tileData = TileTargetedData.new()
		var pos = shapedTile.Position as Vector2
		pos = pos.rotated(deg_to_rad(90 * _directionIndex))

		# Take note of the bullshit you have to do here. Casting directly from a Vector2 to Vector2i ...
		# ... somehow manages to lose values, even if the Vector2 is 100% a Vector2i ...
		# ... the snapped method manages to make it so that it recognizes that 1 and -1 are in fact ints and not 0 value
		var vector2i = Vector2i(pos.snapped(Vector2.ONE))
		var relativePosition = unitOriginTile.Position + vector2i

		var specificDataAsComplex = specificData as Vector2iMultComplex

		var tile = _grid.GetTile(relativePosition) as Tile
		if tile != null:
			tileData.Tile = tile
			tileData.AOEMultiplier = shapedTile.Multiplier
			tileData.CritModifier = shapedTile.get("CritModifier") if shapedTile.get("CritModifier") != null else 0
			tileData.AccuracyModifier = shapedTile.get("AccuracyModifier") if shapedTile.get("AccuracyModifier") != null else 0

			if tile.IsWall && stopShapeOnWall:
				return arr

			if specificDataAsComplex != null:
				if specificDataAsComplex.pushInfo != null:
					var info = specificDataAsComplex.pushInfo
					tileData.pushAmount = info.pushAmount
					tileData.carryLimit = info.carryLimit
					if info.overrideActionDirection:
						tileData.pushDirection = info.pushDirectionOverride
					else:
						tileData.pushDirection = _directionIndex
					_grid.PushCast(tileData)

			arr.append(tileData)
		index += 1

	return arr


func FilterByTargettingFlags(_unit : UnitInstance, _options : Array[TileTargetedData]):
	return _options.filter(func(o : TileTargetedData) : return o.Tile.Occupant == null || (o.Tile.Occupant != null && OnCorrectTeam(_unit, o.Tile.Occupant)) || (o.Tile.Occupant == _unit && CanTargetSelf) || (o.willPush))

func FilterTilesByTargettingFlags(_unit : UnitInstance, _options : Array[Tile]):
	return _options.filter(func(o : Tile) : return o.Occupant == null || (o.Occupant != null && OnCorrectTeam(_unit, o.Occupant)) || (o.Occupant == _unit && CanTargetSelf))


func OnCorrectTeam(_thisUnit : UnitInstance, _otherUnit : UnitInstance):
	if Type == TargetingType.SelfOnly:
		return _thisUnit == _otherUnit

	if TeamTargeting == TargetingTeamFlag.Empty:
		return _otherUnit == null

	return (_otherUnit.UnitAllegiance == _thisUnit.UnitAllegiance && TeamTargeting == TargetingTeamFlag.AllyTeam) || (_otherUnit.UnitAllegiance != _thisUnit.UnitAllegiance && TeamTargeting == TargetingTeamFlag.EnemyTeam) || TeamTargeting == TargetingTeamFlag.All

# Orders the Tiles based on if they're currently occupied by another unit
func OrderTargets(a : Tile, b : Tile) -> bool:
	# Yeah this needs to be here for some reason. If the list contains only 1 Tile, then it'll throw an error without this check
	if is_same(a, b):
		return false

	# Somehow the FALSE here is correct and doesn't throw errors so ya know what ever
	if a.Occupant == null && b.Occupant == null:
		return false

	if a.Occupant != null && b.Occupant == null:
		return true
	elif a.Occupant == null && b.Occupant != null:
		return false

	if a.Occupant != null && b.Occupant != null:
		var aHealth = (a.Occupant.currentHealth / a.Occupant.maxHealth)
		var bHealth = (b.Occupant.currentHealth / b.Occupant.maxHealth)
		return aHealth < bHealth

	return false
