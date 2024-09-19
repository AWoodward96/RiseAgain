extends Node2D
class_name SkillTargetingData

enum TargetingType { Simple, ShapedFree, ShapedDirectional }
enum TargetingTeamFlag { AllyTeam, EnemyTeam, All }

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

	return addtionalTargetedTiles

func GetAffectedTiles(_unit : UnitInstance, _grid : Grid, _tile : Tile):
	var returnThis = GetAdditionalTileTargets(_unit, _grid, _tile)
	return returnThis

func GetTilesInRange(_unit : UnitInstance, _grid : Grid):
	var options =  _grid.GetCharacterAttackOptions(_unit, [_unit.CurrentTile], TargetRange)

	options = FilterTilesByTargettingFlags(_unit, options)

	if options.size() > 1:
		options.sort_custom(OrderTargets)
	return options

func GetDirectionalAttack(_unit : UnitInstance, _grid : Grid, _directionIndex : GameSettingsTemplate.Direction):
	var arr : Array[TileTargetedData]
	var unitOriginTile = _unit.CurrentTile
	if shapedTiles == null:
		return arr

	for t in shapedTiles.GetCoords(_unit, _grid, unitOriginTile):
		var tileData = TileTargetedData.new()
		var pos = t.Position as Vector2
		pos = pos.rotated(deg_to_rad(90 * _directionIndex))

		# Take note of the bullshit you have to do here. Casting directly from a Vector2 to Vector2i ...
		# ... somehow manages to lose values, even if the Vector2 is 100% a Vector2i ...
		# ... the snapped method manages to make it so that it recognizes that 1 and -1 are in fact ints and not 0 value
		var vector2i = Vector2i(pos.snapped(Vector2.ONE))
		var relativePosition = unitOriginTile.Position + vector2i

		var tile = _grid.GetTile(relativePosition) as Tile
		if tile != null:
			tileData.Tile = tile
			tileData.AOEMultiplier = t.Multiplier
			arr.append(tileData)

			if tile.IsWall && stopShapeOnWall:
				return arr

	return arr


func FilterByTargettingFlags(_unit : UnitInstance, _options : Array[TileTargetedData]):
	return _options.filter(func(o : TileTargetedData) : return o.Tile.Occupant == null || (o.Tile.Occupant != null && OnCorrectTeam(_unit, o.Tile.Occupant)) || (o.Tile.Occupant == _unit && CanTargetSelf))

func FilterTilesByTargettingFlags(_unit : UnitInstance, _options : Array[Tile]):
	return _options.filter(func(o : Tile) : return o.Occupant == null || (o.Occupant != null && OnCorrectTeam(_unit, o.Occupant)) || (o.Occupant == _unit && CanTargetSelf))


func OnCorrectTeam(_thisUnit : UnitInstance, _otherUnit : UnitInstance):
	return (_otherUnit.UnitAllegiance == _thisUnit.UnitAllegiance && TeamTargeting == TargetingTeamFlag.AllyTeam) || (_otherUnit.UnitAllegiance != _thisUnit.UnitAllegiance && TeamTargeting == TargetingTeamFlag.EnemyTeam) || TeamTargeting == TargetingTeamFlag.All

# Orders the Tiles based on if they're currently occupied by another unit
static func OrderTargets(a : Tile, b : Tile):
	# Yeah this needs to be here for some reason. If the list contains only 1 Tile, then it'll throw an error without this check
	if a == b:
		return false

	if a.Occupant == null && b.Occupant == null:
		return true

	if a.Occupant != null && b.Occupant == null:
		return true
	elif a.Occupant == null && b.Occupant != null:
		return false

	if a.Occupant != null && b.Occupant != null:
		var aHealth = (a.Occupant.currentHealth / a.Occupant.maxHealth)
		var bHealth = (b.Occupant.currentHealth / b.Occupant.maxHealth)
		return aHealth < bHealth

	return false
