extends Node2D
class_name SkillTargetingData

enum TargetingType { Simple, ShapedFree, ShapedDirectional }
enum TargetingTeamFlag { AllyTeam, EnemyTeam, All }

@export var TeamTargeting : TargetingTeamFlag = TargetingTeamFlag.EnemyTeam

# x = min, y = max
@export var TargetRange : Vector2i = Vector2i(1, 1)
@export var Type : TargetingType

# TODO: Implement a way to do shaped targeting
@export var shapedPrefab : PackedScene


func GetAdditionalTileTargets(_tile : Tile):
	var addtionalTargetedTiles : Array[Tile]
	match Type:
		TargetingType.Simple:
			addtionalTargetedTiles.append(_tile)
		TargetingType.ShapedFree:
			pass
		TargetingType.ShapedDirectional:
			pass

	return addtionalTargetedTiles

func GetTilesInRange(_unit : UnitInstance, _grid : Grid):
	var options =  _grid.GetCharacterAttackOptions(_unit, [_unit.CurrentTile], TargetRange)

	if Type == TargetingType.Simple:
		options = FilterByTargettingFlags(_unit, options)

	options.sort_custom(OrderTargets)
	return options

func FilterByTargettingFlags(_unit : UnitInstance, _options : Array[Tile]):
	return _options.filter(func(o : Tile) : return o.Occupant == null || (o.Occupant != null && OnCorrectTeam(_unit, o.Occupant)))

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
