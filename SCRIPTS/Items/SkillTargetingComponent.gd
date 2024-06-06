extends Node2D
class_name SkillTargetingData

enum TargetingType { Simple, ShapedFree, ShapedDirectional }
enum TargetingTeamFlag { AllyTeam, EnemyTeam, All }

@export var TeamTargeting : TargetingTeamFlag = TargetingTeamFlag.EnemyTeam

# x = min, y = max
@export var TargetRange : Vector2i = Vector2i(1, 1)
var TilesInRange : Array[Tile]
@export var Type : TargetingType

# TODO: Implement a way to do shaped targeting
@export var shapedPrefab : PackedScene


func GetAdditionalTileTargets(_tile : Tile):
	#match Type:
		#TargetingType.Simple:
			#return [_tile]
		#TargetingType.ShapedFree:
			#return _tile
		#TargetingType.ShapedDirectional:
			#return _tile

	return [_tile]

func GetAndShowTilesInRange(_unit : UnitInstance, _grid : Grid):
	_grid.ClearActions()
	var options =  _grid.GetCharacterAttackOptions(_unit, [_unit.CurrentTile], TargetRange)

	if Type == TargetingType.Simple:
		options = FilterByTargettingFlags(_unit, options)

	options.sort_custom(OrderTargets)
	TilesInRange = options

	_grid.ShowActions()
	pass

func FilterByTargettingFlags(_unit : UnitInstance, _options : Array[Tile]):
	return _options.filter(func(o : Tile) : return o.Occupant == null || (o.Occupant != null && (o.Occupant.UnitAllegiance == _unit.UnitAllegiance && TeamTargeting == TargetingTeamFlag.AllyTeam) || (o.Occupant.UnitAllegiance != _unit.UnitAllegiance && TeamTargeting == TargetingTeamFlag.EnemyTeam) || TeamTargeting == TargetingTeamFlag.All))

# Orders the Tiles based on if they're currently occupied by another unit
func OrderTargets(a : Tile, b : Tile):
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

	return true
