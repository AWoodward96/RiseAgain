extends EnemyAIOption
class_name LandingLeapAIOption

static func Construct(_source : UnitInstance, _target : UnitInstance, _map : Map, _ability : Ability):
	var option = LandingLeapAIOption.new()
	option.map = _map
	option.grid = _map.grid
	option.sourceUnit = _source
	option.targetUnit = _target
	option.ability = _ability
	return option

func Update():
	# This should be pretty simple. Grab all adjacent tiles next to an enemy
	# If any of them are in range they're valid
	# first grab the adjacent tiles
	var adjacentTiles : Array[Tile] = GetValidTiles()
	if adjacentTiles.size() == 0:
		# I'm ngl I don't know what to do if this happens
		valid = false
		return

	# prioritize maximum units hit with this ability
	var unitsHit = 0
	var selectedTile : Tile = null
	var affectedTiles : Array[TileTargetedData] = []
	for tile in adjacentTiles:
		if !grid.CanUnitFitOnTile(sourceUnit, tile, sourceUnit.IsFlying, true, false):
			continue

		var localAffectedTiles = ability.TargetingData.GetAffectedTiles(sourceUnit, grid, tile, 0)
		var localHit = 0
		for hitTile in localAffectedTiles:
			if hitTile.Tile.Occupant != null && SkillTargetingData.OnCorrectTeam(ability.TargetingData.Type, ability.TargetingData.TeamTargeting, sourceUnit, hitTile.Tile.Occupant):
				localHit += 1

		if localHit > unitsHit:
			selectedTile = tile
			unitsHit = localHit
			affectedTiles = localAffectedTiles

	if selectedTile != null:
		valid = true
		tileToAttack = selectedTile
		tilesHitByAttack = affectedTiles
		canAttack = true



func GetValidTiles():
	var range = ability.GetRange()
	var validTiles : Array[Tile] = []
	var neighborCoords : Array[Vector2i] = []
	match sourceUnit.Template.GridSize:
		1:
			neighborCoords = Grid.NEIGHBORS
		2:
			neighborCoords = Grid.SIZE2X2_ADJACENTTILES

	for neighborCoord in neighborCoords:
		var newCoord = targetUnit.GridPosition + neighborCoord
		var tile = grid.GetTile(newCoord)
		if tile == null:
			continue

		if !grid.CanUnitFitOnTile(sourceUnit, tile, sourceUnit.IsFlying, true, false):
			continue

		var manhattan = grid.GetManhattanDistance(sourceUnit.GridPosition, newCoord)
		if manhattan > range.x && manhattan < range.y:
				validTiles.append(tile)
	return validTiles
