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


func GetAdditionalTileTargets(_unit : UnitInstance, _grid : Grid, _tile : Tile):
	var addtionalTargetedTiles : Array[Tile]
	match Type:
		TargetingType.Simple:
			addtionalTargetedTiles.append(_tile)
		TargetingType.ShapedFree:
			if shapedTiles != null:
				addtionalTargetedTiles.append_array(shapedTiles.GetTiles(_unit, _grid, _tile))

			addtionalTargetedTiles = FilterByTargettingFlags(_unit, addtionalTargetedTiles)
			pass
		TargetingType.ShapedDirectional:
			pass

	return addtionalTargetedTiles

func GetTilesInRange(_unit : UnitInstance, _grid : Grid):
	var options =  _grid.GetCharacterAttackOptions(_unit, [_unit.CurrentTile], TargetRange)

	options = FilterByTargettingFlags(_unit, options)

	options.sort_custom(OrderTargets)
	return options

func GetDirectionalAttackOptions(_unit : UnitInstance, _grid : Grid):
	var dict = {}
	var unitOriginTile = _unit.CurrentTile
	if shapedTiles == null:
		return dict

	# NOTE: I would LOVE it if I could use a fucking Enum here, but as of Godot 4.2.2
	# THAT DOESNT WORK LOLOL
	# It just gets cast to a 0. So that's cool.
	for i in 4:
		var arr : Array[Tile]
		for t in shapedTiles.GetCoords(_unit, _grid, unitOriginTile):
			var pos = t as Vector2
			pos = pos.rotated(deg_to_rad(90 * i))

			# Take note of the bullshit you have to do here. Casting directly from a Vector2 to Vector2i ...
			# ... somehow manages to lose values, even if the Vector2 is 100% a Vector2i ...
			# ... the snapped method manages to make it so that it recognizes that 1 and -1 are in fact ints and not 0 value
			var vector2i = Vector2i(pos.snapped(Vector2.ONE))
			var relativePosition = unitOriginTile.Position + vector2i

			var tile = _grid.GetTile(relativePosition)
			if tile != null:
				arr.append(tile)
		dict[i] = arr
	return dict

# Should take the output of GetDirectionalAttackOptions
func GetBestDirectionForDirectionalShaped(_dict : Dictionary):
	var returnDir = -1
	var targetCount = 0
	var bestCount = 0
	for key in _dict:
		if _dict[key].size() == 0:
			continue

		for tile in _dict[key]:
			if tile.Occupant != null:
				targetCount += 1

		if targetCount >= bestCount:
			returnDir = key
			bestCount = targetCount
		targetCount = 0
	return returnDir

func FilterByTargettingFlags(_unit : UnitInstance, _options : Array[Tile]):
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
