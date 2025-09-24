extends Node2D
class_name SkillTargetingData

enum TargetingType { Simple, ShapedFree, ShapedDirectional, SelfOnly, Global }
enum TargetingTeamFlag { AllyTeam, EnemyTeam, All, Empty }

@export var TeamTargeting : TargetingTeamFlag = TargetingTeamFlag.EnemyTeam

# x = min, y = max
@export var TargetRange : Vector2i = Vector2i(1, 1)
@export var Type : TargetingType
@export var CanTargetSelf : bool = false

@export var shapedTiles : TargetingShapeBase
@export var stopShapeOnWall : bool = false

var ability : Ability


func GetAdditionalTileTargets(_unit : UnitInstance, _grid : Grid, _tile : Tile, _atRange : int = 0):
	var addtionalTargetedTiles : Array[TileTargetedData]
	match Type:
		TargetingType.Simple:
			addtionalTargetedTiles.append(_tile.AsTargetData())
		TargetingType.ShapedFree:
			if shapedTiles != null:
				addtionalTargetedTiles.append_array(shapedTiles.GetTileData(_unit, ability, _grid, _tile, _atRange))
			addtionalTargetedTiles = FilterByTargettingFlags(_unit, addtionalTargetedTiles)
			pass
		TargetingType.ShapedDirectional:
			pass
		TargetingType.SelfOnly:
			addtionalTargetedTiles = [_unit.CurrentTile.AsTargetData()]

	if ability.IsHeal():
		addtionalTargetedTiles = FilterByHeal(addtionalTargetedTiles)

	return addtionalTargetedTiles

func GetAffectedTiles(_unit : UnitInstance, _grid : Grid, _tile : Tile, _atRange : int = 0):
	var returnThis = GetAdditionalTileTargets(_unit, _grid, _tile, _atRange)
	return returnThis

func GetTilesInRange(_unit : UnitInstance, _grid : Grid, _sort : bool = true):
	var options : Array[Tile]
	if Type == TargetingType.SelfOnly:
		options = [_unit.CurrentTile]
	else:
		options = _grid.GetCharacterAttackOptions(_unit, [_unit.CurrentTile], TargetRange)

	options = FilterTilesByTargettingFlags(_unit, options)


	if ability.IsHeal():
		options = FilterByHeal(options)

	if options.size() > 1 && _sort:
		options.sort_custom(OrderTargets)
	return options


func GetDirectionalAttack(_unit : UnitInstance, _ability : Ability, _origin : Tile, _atRange : int, _grid : Grid, _directionIndex : GameSettingsTemplate.Direction):
	return shapedTiles.GetTargetedTilesFromDirection(_unit, _ability, _grid, _origin, _directionIndex, _atRange)

func GetGlobalAttack(_sourceUnit : UnitInstance, _map : Map, _directionIndex : GameSettingsTemplate.Direction):
	var returnTiles : Array[TileTargetedData] = []
	for team in _map.teams:
		for targetUnit : UnitInstance in _map.teams[team]:
			if targetUnit == null:
				continue

			if OnCorrectTeam(_sourceUnit, targetUnit):
				if shapedTiles != null:
					returnTiles.append_array(shapedTiles.GetTargetedTilesFromDirection(_sourceUnit, ability, _map.grid, targetUnit.CurrentTile, _directionIndex, 0, false, true))
				else:
					returnTiles.append(targetUnit.CurrentTile.AsTargetData())
			else:
				# Since the units are sorted into the proper teams, we can slightly optimize this by just breaking out if we ever detect a unit on the wrong team
				break

	return returnTiles

func FilterByTargettingFlags(_unit : UnitInstance, _options : Array[TileTargetedData]):
	return _options.filter(func(o : TileTargetedData) : return (o.Tile.Occupant == null && o.HitsEnvironment) || (o.Tile.Occupant != null && OnCorrectTeam(_unit, o.Tile.Occupant) && !o.Tile.Occupant.IsDying) || (o.Tile.Occupant == _unit && CanTargetSelf && !o.Tile.Occupant.IsDying) || (o.willPush))

func FilterTilesByTargettingFlags(_unit : UnitInstance, _options : Array[Tile]):
	return _options.filter(func(o : Tile) : return o.Occupant == null ||  (o.Occupant != null && OnCorrectTeam(_unit, o.Occupant) && !o.Occupant.IsDying) || (o.Occupant == _unit && CanTargetSelf && !o.Occupant.IsDying))

func FilterByHeal(_options : Array):
	if _options[0] is Tile:
		return _options.filter(func(o : Tile) : return o.Occupant != null && o.Occupant.CanHeal)
	elif _options[0] is TileTargetedData:
		return _options.filter(func(o : TileTargetedData) : return o.Tile.Occupant != null && o.Tile.Occupant.CanHeal)
	return _options

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
