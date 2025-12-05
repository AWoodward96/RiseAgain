class_name Grid

const THREATLAYER = 1
const ACTIONOPTIONSLAYER = 2
const UITILEATLAS = 2
const FIRETILEATLAS = 6
const ATTACKTILE = Vector2i(2,0)
const BUFFTILE = Vector2i(3,0)
const RANGETILE = Vector2i(1,0)
const MOVETILE = Vector2i(0,0)
const BASEBLACKTILE = Vector2i(3, 1)
const THREATTILE_1 = Vector2i(0,1)
const THREATTILE_2 = Vector2i(1,1)
const THREATTILE_3 = Vector2i(2,1)
const FIRETILE_1 = Vector2i(0,0)
const FIRETILE_2 = Vector2i(0,1)
const FIRETILE_3 = Vector2i(0,2)
const NEIGHBORS : Array[Vector2i] = [Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0)]

# remember: thse coordinates should be where a 2x2 unit can stand RELATIVE TO ANOTHER UNIT
# NOT, what are the tiels that are adjacent to a 2x2 unit
const SIZE2X2_ADJACENTTILES : Array[Vector2i] = [Vector2i(-2, -1), Vector2i(-2, 0), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, -2), Vector2i(0, -2), Vector2i(1,0), Vector2i(1,-1)]


var GridArr : Array[Tile]
var Width: int
var Height: int
var map : Map
var CellSize : int
var ShowingThreat : bool

var Shrouds : Array[ShroudInstance]
var StartingPositions : Array[Vector2i]
var CanvasModLayer : TileMapLayer


func Init(_width : int, _height : int, _map : Map, _cell_size : int):
	Width = _width
	Height = _height
	CellSize = _cell_size
	map = _map


	CanvasModLayer = GameManager.GameSettings.GridModulatePrefab.instantiate() as TileMapLayer
	map.add_child(CanvasModLayer)

	# no 2d arrays, cowabunga it is
	GridArr.resize(Width*Height)
	for x in Width:
		for y in Height:
			var index = y * Width + x
			GridArr[index] = Tile.new()
			GridArr[index].Position = Vector2i(x,y)
			GridArr[index].GlobalPosition = Vector2(x * CellSize, y *CellSize)

			var bg_data = map.tilemap_bg.get_cell_tile_data(Vector2i(x,y))
			if bg_data != null:
				GridArr[index].BGTileData = bg_data.get_custom_data("MetaData") as TileMetaData

			if map.tilemap_water != null:
				var water_data = map.tilemap_water.get_cell_tile_data(Vector2i(x,y))
				if water_data != null:
					GridArr[index].SubBGTileData = water_data.get_custom_data("MetaData") as TileMetaData


			if map.tilemap_main != null:
				var main_data = map.tilemap_main.get_cell_tile_data(Vector2i(x,y))
				if main_data:
					if main_data.get_collision_polygons_count(0) > 0 :
						GridArr[index].IsWall = true

					GridArr[index].MainTileData = main_data.get_custom_data("MetaData") as TileMetaData

			if map.tilemap_destructable != null:
				var destructable_data = map.tilemap_destructable.get_cell_tile_data(Vector2i(x,y))
				if destructable_data:
					if destructable_data.get_collision_polygons_count(0) > 0:
						GridArr[index].IsWall = true

					GridArr[index].DestructableData = destructable_data.get_custom_data("MetaData") as TileMetaData

			GridArr[index].InitMetaData()

			# The canvas mod has a shader that replaces any tile on it with a grid overlay - np
			CanvasModLayer.set_cell(Vector2i(x,y), UITILEATLAS, BASEBLACKTILE)
	RefreshShroud()

func RefreshShroud():
	var visited : Dictionary
	Shrouds.clear()
	for currentTile in GridArr:
		if !currentTile.IsShroud:
			continue

		if visited.has(currentTile):
			continue

		var frontier : Array[Tile]
		var clump : Array[Tile]
		frontier.append(currentTile)

		while(frontier.size() > 0):
			var tile = frontier.pop_front()
			var neighbors = GetAdjacentTiles(tile) as Array[Tile]
			visited[tile] = true
			clump.append(tile)

			for neigh in neighbors:
				if neigh.IsShroud && !visited.has(neigh) && !frontier.has(neigh):
					frontier.append(neigh)

				pass
		# We should have a clump at this point
		Shrouds.append(ShroudInstance.Construct(clump, map))


func RefreshGridForTurn(_allegience : GameSettingsTemplate.TeamID):
	var allAlliedUnits : Array[UnitInstance] = []
	if _allegience == GameSettingsTemplate.TeamID.ENEMY:
		allAlliedUnits = map.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ALLY)

	for x in Width:
		for y in Height:
			var index = y * Width + x
			var currentTile = GridArr[index]
			RefreshTilesCollision(currentTile, _allegience)

			# Update the dijkstra map since we're already in here
			if _allegience == GameSettingsTemplate.TeamID.ENEMY:
				var currentManhattan = Width * Height
				for unit in allAlliedUnits:
					var newManhattan = GetManhattanDistance(currentTile.Position, unit.GridPosition)
					if newManhattan < currentManhattan:
						currentTile.playerDijkstra = newManhattan
						currentManhattan = newManhattan


func RefreshTilesCollision(_tile : Tile, _allegience : GameSettingsTemplate.TeamID):
	if _tile == null:
		return

	var x = _tile.Position.x
	var y = _tile.Position.y

	var main_data = null
	var destructable_data = null

	if map.tilemap_main != null: main_data =  map.tilemap_main.get_cell_tile_data(Vector2i(x,y))
	if map.tilemap_destructable != null: destructable_data = map.tilemap_destructable.get_cell_tile_data(Vector2i(x,y))

	_tile.IsWall = false
	if main_data:
		if main_data.get_collision_polygons_count(0) > 0 :
			_tile.IsWall = true

	if destructable_data:
		if destructable_data.get_collision_polygons_count(0) > 0 && _tile.Health > 0:
			_tile.IsWall = true

	_tile.RefreshActiveKillbox()


func ShowUnitActions(_unit : UnitInstance):
	ClearActions()
	var movement = GetCharacterMovementOptions(_unit)
	var unitRange = _unit.GetEffectiveAttackRange()
	GetCharacterAttackOptions(_unit, movement, unitRange)
	ShowActions()

func ShowThreat(_show : bool, _units : Array[UnitInstance]):
	ShowingThreat = _show

	if !ShowingThreat:
		map.tilemap_threat.clear()
		return

	RefreshThreat(_units)

func RefreshThreat(_units : Array[UnitInstance]):
	map.tilemap_threat.clear()
	var workingList = GetWorkingThreatList(_units)

	for tile in workingList:
		var numberOfAppearances = workingList.count(tile)
		match numberOfAppearances:
			0:
				pass
			1:
				map.tilemap_threat.set_cell(tile.Position, UITILEATLAS, THREATTILE_1)
			2:
				map.tilemap_threat.set_cell(tile.Position, UITILEATLAS, THREATTILE_2)
			_:
				map.tilemap_threat.set_cell(tile.Position, UITILEATLAS, THREATTILE_3)

func GetWorkingThreatList(_units : Array[UnitInstance], _excludeShrouded : bool = true):
	var workingList : Array[Tile]
	for u in _units:
		if u == null || u.currentHealth <= 0 || (_excludeShrouded && u.ShroudedFromPlayer):
			continue

		var movement = GetCharacterMovementOptions(u, false)

		var unitRange = u.GetEffectiveAttackRange()
		var threatRange = GetCharacterAttackOptions(u, movement, unitRange, false)
		threatRange = GetUniqueTiles(threatRange)
		workingList.append_array(threatRange)
	return workingList

static func GetUniqueTiles(_array : Array[Tile]):
	var returnMe : Array[Tile] = []

	for tile in _array:
		if !returnMe.has(tile):
			returnMe.append(tile)

	return returnMe

func ClearActions() :
	for n in GridArr:
		n.CanMove = false
		n.CanAttack = false
		n.InRange = false
		n.CanBuff = false

	map.tilemap_UI.clear()

func ShowActions() :
	for n in GridArr :
		# TODO: Do a run or two to see if this being commented out is a problem
		#if n.Occupant != null :
			#continue

		if n.InRange :
			map.tilemap_UI.set_cell(n.Position, UITILEATLAS, RANGETILE)

		if n.CanMove :
			map.tilemap_UI.set_cell(n.Position, UITILEATLAS, MOVETILE)
			continue

		if n.CanAttack :
			map.tilemap_UI.set_cell(n.Position, UITILEATLAS, ATTACKTILE)

		if n.CanBuff :
			map.tilemap_UI.set_cell(n.Position, UITILEATLAS, BUFFTILE)



func GetCharacterMovementOptions(_unit : UnitInstance, _markTiles : bool = true) :
	var returnList : Array[Tile] = []
	var frontier : Array[Tile] = []
	var visited : Dictionary

	# --- How does this work? ---
	# the return list keeps track of a list to return. Even though this algorithm marks tiles as CanMove - there are cases where I actually need an array of the tiles
	# the frontier is the engine of the algorithm. By adding to it and popping off Tiles, we can traverse the grid
	# the visited dictionary is a dict of a Tile visited, and how much movement it'll take to get there.
	# As the frontier moves through the grid, store tiles in the visited dictionary with a value equal to the current.movement + 1
	# Once the current tile's movement value in the visited dictionary exceeds the units movement the algorithm is complete
	# --------------------------

	var startingIndex = _unit.GridPosition.y * Width + _unit.GridPosition.x

	var unitHasFlying = _unit.Template.Descriptors.has(GameManager.GameSettings.FlyingDescriptor)

	var movement = _unit.GetUnitMovement()
	# include the tile they're currently on as an option - always - even if it could literally kill them in some circumstances
	returnList.append(GridArr[startingIndex])
	frontier.append(GridArr[startingIndex])
	visited[GridArr[startingIndex]] = 0

	while !frontier.is_empty():
		var current = frontier.pop_front() as Tile
		if _markTiles:
			current.CanMove = true

		if visited[current] > movement:
			break

		for neigh in NEIGHBORS:
			var neighborLocation = current.Position + neigh
			var tile = GetTile(neighborLocation) as Tile
			if tile == null:
				continue

			if visited.has(tile):
				continue

			if !tile.Traversable(_unit, unitHasFlying):
				continue

			if !CanUnitFitOnTile(_unit, tile, unitHasFlying, true, true):
				continue

			var occupant = tile.Occupant
			if (occupant == null) || (occupant != null && occupant.UnitAllegiance == _unit.UnitAllegiance) || (occupant != null && occupant.ShroudedFromPlayer):
				if visited[current] + 1 > movement:
					break
				visited[tile] = visited[current] + 1
				returnList.append(tile)
				frontier.append(tile)
	return returnList

func SwapUnitPositions(_unit1 : UnitInstance, _unit2 : UnitInstance):
	var index1 = GetGridArrIndex(_unit1.GridPosition)
	var index2 = GetGridArrIndex(_unit2.GridPosition)

	GridArr[index1].Occupant = _unit2
	GridArr[index2].Occupant = _unit1

	_unit1.GridPosition = GridArr[index2].Position
	_unit1.CurrentTile = GridArr[index2]
	_unit1.global_position = GridArr[index2].Position * CellSize

	_unit2.GridPosition = GridArr[index1].Position
	_unit2.CurrentTile = GridArr[index1]
	_unit2.global_position = GridArr[index1].Position * CellSize


func SetUnitGridPosition(_unit : UnitInstance, _newPosition : Vector2i, _updateWorldPosition : bool, _allowOccupantOverwrite : bool = false) :
	# Clear out the previous Positions Occupant so that
	# we don't duplicate this units position in the Grid
	var position = _unit.GridPosition
	var unitSize = _unit.Template.GridSize

	# Some units have sizes that are greater than 1.
	# Make sure that units know where these units actually are
	for i in range(0, unitSize):
		for j in range(0, unitSize):
			position =  _unit.GridPosition + Vector2i(i,j)
			var gridIndex = GetGridArrIndex(position)
			if GridArr[gridIndex].Occupant == _unit:
				GridArr[gridIndex].Occupant = null

	# update the physical location of the unit
	if _updateWorldPosition:
		_unit.global_position = _newPosition * CellSize

	_unit.GridPosition = _newPosition

	position = _newPosition
	for i in range(0, unitSize):
		for j in range(0, unitSize):
			position = _newPosition + Vector2i(i,j)
			var newIndex = GetGridArrIndex(position)
			if GridArr[newIndex].Occupant == null:
				GridArr[newIndex].Occupant = _unit
			else:
				if _allowOccupantOverwrite:
					GridArr[newIndex].Occupant = _unit
				else:
					push_error("Unit: {0} want's to end up on tile {1}, but it's currently occupied by {2}. If this is the intended behavior, ignore this, but otherwise this may be a problem.".format([_unit.Template.DebugName, str(_newPosition), GridArr[newIndex].Occupant.Template.DebugName]))


	_unit.CurrentTile = GridArr[GetGridArrIndex(_newPosition)]
	_unit.OnTileUpdated(_unit.CurrentTile)

	# See: UnitMoveAction for where the killbox gets checked
	#_unit.CheckKillbox()

func FindNearbyValidTile(_invalidTile : Tile, _originTile : Tile):
	var frontier : Array[Tile]
	frontier.append(_invalidTile)

	var validTiles : Array[Tile]
	while frontier.size() > 0 && validTiles.size() == 0:
		var current = frontier.pop_front()
		var neighbors = GetAdjacentTiles(current)
		for neigh : Tile in neighbors:
			if !neigh.IsWall && neigh.Occupant == null && !neigh.ActiveKillbox:
				validTiles.append(neigh)
			else:
				frontier.append(neigh)

	if validTiles.size() == 0:
		push_error("FindNearbyValidTile found no valid nearby tiles. Is every single tile on the map full??")
		return _originTile

	var bestTile : Tile = null
	var heuristic = 100
	for option : Tile in validTiles:
		var distance = GetManhattanDistance(option.Position, _originTile.Position)
		if distance < heuristic:
			bestTile = option
			heuristic = distance

	if bestTile == null:
		bestTile = _originTile

	return bestTile


func GetGridArrIndex(_pos : Vector2i):
	return _pos.y * Width + _pos.x

func GetTile(_pos : Vector2i):
	if _pos.x >= Width:
		_pos.x = Width - 1 # Index'd 0, remember
	if _pos.y >= Height:
		_pos.y = Height - 1

	if _pos.x < 0:
		_pos.x = 0
	if _pos.y < 0:
		_pos.y = 0

	var index = GetGridArrIndex(_pos)
	if index < 0 || index >= GridArr.size():
		return null
	return GridArr[index]

func GetTileFromGlobalPosition(_position : Vector2):
	var xInt = roundi(_position.x / CellSize)
	var yInt = roundi(_position.y / CellSize)

	return GetTile(Vector2i(xInt, yInt))

func PositionIsInGridBounds(_pos : Vector2i):
	return _pos.y >= 0 && _pos.x >= 0 && _pos.x < Width && _pos.y < Height

func GetAdjacentTiles(_tile : Tile):
	var arr : Array[Tile]
	for n in NEIGHBORS:
		var t = GetTile(_tile.Position + n)
		if t != null:
			arr.append(t)
	return arr

func GetCharacterAttackOptions(_unit : UnitInstance, _workingList : Array[Tile], _attackRange : Vector2i, _markTiles : bool = true) :
	var returnArr : Array[Tile] = []
	if _attackRange.x <= 1:
		# include the current tile
		returnArr.append(_workingList[0])

	for n in _workingList :
		for x in range(-_attackRange.y, _attackRange.y + 1) :
			for y in range(-_attackRange.y, _attackRange.y + 1) :
				if (x == 0 && y == 0) || (_unit.GridPosition == n.Position + Vector2i(x,y)) :
					continue

				var position = n.Position as Vector2 + Vector2(x,y)
				if (PositionIsInGridBounds(position)):
					#var dst = position.distance_to(n.Position as Vector2)
					var dst = position - (n.Position as Vector2)
					var riseOverRun = abs(dst.x) + abs(dst.y)
					if (riseOverRun >= _attackRange.x && riseOverRun <= _attackRange.y) :
						if _markTiles:
							GridArr[position.y * Width + position.x].CanAttack = true

						returnArr.append(GridArr[position.y * Width + position.x])
	return returnArr

func GetTilesWithinRange(_origin : Vector2i, _range : Vector2i, _includeOrigin = false):
	var returnArr : Array[Tile] = []
	for x in range(-_range.y, _range.y + 1):
		for y in range(-_range.y, _range.y + 1):
			if x == 0 && y == 0 && !_includeOrigin:
				continue

			var position = _origin as Vector2 + Vector2(x,y)
			if PositionIsInGridBounds(position):
				var dst = position.distance_to(_origin as Vector2)
				if dst >= _range.x && dst <= _range.y :
					returnArr.append(GridArr[position.y * Width + position.x])
	return returnArr


func ModifyTileHealth(_healthDelta : int, _tile : Tile, _showDamageNumbers : bool = true):
	if _tile.MaxHealth <= 0:
		return

	_tile.Health += _healthDelta
	if _showDamageNumbers:
		Juice.CreateDamagePopup(_healthDelta, _tile)

	var hitSoundKill = "event:/SFX/Combat_TakeDamage_Kill"
	var hitSoundHurt = "event:/SFX/Combat_TakeDamage_Standard"

	var event
	if _tile.Health <= 0:
		DestroyTerrain(_tile, true)
		# We do it like this so that you can't retarget this tile anymore
		_tile.MaxHealth = -1
		_tile.Health = 0
		event = FmodServer.create_event_instance(hitSoundKill)
	else:
		event = FmodServer.create_event_instance(hitSoundHurt)

	event.start()


func DestroyTerrain(_tile : Tile, _playVFX : bool):
	_tile.TerrainDestroyed = true

	if _tile.DestructableData != null:
		if _tile.DestructableData.DestructionRewards.size() > 0:
			PersistDataManager.universeData.AddResources(_tile.DestructableData.DestructionRewards, (_tile.Position * CellSize) + Vector2i(CellSize / 2, CellSize / 2))

		if _tile.DestructableData.DestructionVFXPrefab != null && _playVFX:
			var vfx = _tile.DestructableData.DestructionVFXPrefab.instantiate()
			vfx.position = _tile.GlobalPosition
			map.add_child(vfx)

	map.tilemap_destructable.set_cell(_tile.Position)
	RefreshTilesCollision(_tile, map.currentTurn as int)


func GetPathBetweenTwoUnits(_originUnit : UnitInstance, _destinationUnit : UnitInstance):
	# Note that this will take the rough path as well - so a movement path that is imper
	return GetTilePath(_originUnit, _originUnit.CurrentTile, _destinationUnit.CurrentTile, false, true)

func GetGreedyTilePath(_unitInstance : UnitInstance, _startingTile : Tile, _endingTile : Tile, _different_teams_are_walls : bool = true, _ignore_shrouded_units : bool = true):
	var frontier = PriorityQueue_Tile.new()
	frontier.Enqueue(TileQueue.Construct(_startingTile, 0))
	var visited : Dictionary
	visited[_startingTile] = null

	var unitIsFlying = false
	if _unitInstance != null:
		unitIsFlying = _unitInstance.Template.Descriptors.has(GameManager.GameSettings.FlyingDescriptor)

	var lowestValue = 100000
	var lowestTile = _startingTile
	var success = false

	while (!frontier.size == 0):
		var current = frontier.Dequeue().tile

		if current == _endingTile:
			success = true
			break

		for neigh in NEIGHBORS:
			var neighborLocation = current.Position + neigh
			var nextTile = GetTile(neighborLocation) as Tile
			if nextTile == null:
				continue

			if !visited.has(nextTile):
				# Early Exit: Unit isn't flying, and there is a wall there
				# Early Exit: The next tile is a killbox - don't let them willingly move over them
				if !nextTile.Traversable(_unitInstance, unitIsFlying):
					continue


				if !CanUnitFitOnTile(_unitInstance, nextTile, unitIsFlying, _different_teams_are_walls, _ignore_shrouded_units):
					continue

				if _unitInstance != null:
					if _different_teams_are_walls && !unitIsFlying && nextTile.Occupant != null && nextTile.Occupant.UnitAllegiance != _unitInstance.UnitAllegiance:
						continue

				var prio = HeuristicManhattan(_endingTile, nextTile)
				frontier.Enqueue(TileQueue.Construct(nextTile, prio))
				visited[nextTile] = current

				if lowestValue > prio:
					lowestValue = prio
					lowestTile = nextTile

	var walkback = _endingTile
	if !success:
		walkback = lowestTile

	var returnMe : Array[Tile] = []
	returnMe.append(walkback)
	while walkback != _startingTile:
		returnMe.append(visited[walkback])
		walkback = visited[walkback]

	returnMe.reverse()
	returnMe.remove_at(0) # To remove the tile you're currently on
	return returnMe


func GetTilePath(_unitInstance : UnitInstance, _startingTile : Tile, _endingTile : Tile, _different_teams_are_walls : bool = true, _roughPath : bool = false, _ignore_shrouded_units : bool = true):
	var frontier = PriorityQueue_Tile.new()
	frontier.Enqueue(TileQueue.Construct(_startingTile, 0))

	var visited : Dictionary
	var visitedCost : Dictionary
	visited[_startingTile] = null
	visitedCost[_startingTile] = 0

	var unitIsFlying = false
	if _unitInstance != null:
		unitIsFlying = _unitInstance.Template.Descriptors.has(GameManager.GameSettings.FlyingDescriptor)

	var success = false
	while (!frontier.size == 0):
		var currentTile = frontier.Dequeue().tile

		if currentTile == _endingTile:
			success = true
			break

		for neigh in NEIGHBORS:
			var neighborLocation = currentTile.Position + neigh
			var nextTile = GetTile(neighborLocation)
			if nextTile == null:
				continue

			# Early Exit: Unit isn't flying, and there is a wall there
			# Early Exit: The next tile is a killbox - don't let them willingly move over them
			if !nextTile.Traversable(_unitInstance, unitIsFlying):
				continue

			if !CanUnitFitOnTile(_unitInstance, nextTile, unitIsFlying, _different_teams_are_walls, _ignore_shrouded_units):
				continue

			if _unitInstance != null:
				if _different_teams_are_walls && !unitIsFlying && nextTile.Occupant != null && nextTile.Occupant.UnitAllegiance != _unitInstance.UnitAllegiance:
					continue

			# There is at this time, no terrain modifiers that decreases the movement, therefore
			# the cost to travel is equal to 1 at all times
			var costToTravel = visitedCost[currentTile] + 1

			if !visitedCost.has(nextTile) || costToTravel < visitedCost[nextTile]:
				visitedCost[nextTile] = costToTravel
				var priority = costToTravel + HeuristicManhattan(currentTile, nextTile)
				frontier.Enqueue(TileQueue.Construct(nextTile, priority))
				visited[nextTile] = currentTile


	var returnMe : Array[Tile] = []
	if !success:
		if _roughPath:
			return GetGreedyTilePath(_unitInstance, _startingTile, _endingTile, _different_teams_are_walls)
		return returnMe

	var walkback = _endingTile
	returnMe.append(walkback)
	while walkback != _startingTile:
		returnMe.append(visited[walkback])
		walkback = visited[walkback]

	returnMe.reverse()
	return returnMe

func CanUnitFitOnTile(_unitInstance : UnitInstance, _tile : Tile, _unitIsFlying : bool, _opposingTeamIsWall : bool, _ignoreShroudedUnits = true):
	if _unitInstance == null:
		return true

	if _unitInstance.Template.GridSize == 1:
		return _tile.Occupant == null || (_tile.Occupant.UnitAllegiance == _unitInstance.UnitAllegiance) || !_opposingTeamIsWall || (_tile.Occupant != null && _tile.Occupant.ShroudedFromPlayer && _ignoreShroudedUnits)

	for i in range(0, _unitInstance.Template.GridSize):
		for j in range(0, _unitInstance.Template.GridSize):
			var position = _tile.Position + Vector2i(i,j)
			var tileFromSize = GetTile(position)
			if tileFromSize == null: # Can't fit here, bc then you'd bleed off the map a little bit
				return false

			# Case: Unit isn't flying, and there's a wall or a killbox here
			if !_unitIsFlying:
				if tileFromSize.IsWall || tileFromSize.ActiveKillbox:
					return false

			# Case: There is a unit that doesn't match your allegience here
			if _opposingTeamIsWall:
				if tileFromSize.Occupant != null && (tileFromSize.Occupant.UnitAllegiance != _unitInstance.UnitAllegiance):
					if tileFromSize.Occupant.ShroudedFromPlayer && _ignoreShroudedUnits:
						continue
					else:
						return false

	return true

func HeuristicManhattan(_tileA : Tile, _tileB : Tile):
	return abs(_tileA.Position.x - _tileB.Position.x) + abs(_tileA.Position.y - _tileB.Position.y)

func PushCast(_tileData : TileTargetedData):
	if _tileData == null || _tileData.Tile == null:
		return

	if !_tileData.willPush:
		push_error("Attempting to pushcast with an invalid origin tile. Tile: " + str(_tileData.Tile.Position))

	var currentTile = _tileData.Tile

	# Check the origin tile for an occupant - if there's one there add them to the stack.
	if currentTile.Occupant != null && currentTile.Occupant.Template.GridSize == 1:
		var newResult = PushResult.new()
		newResult.Subject = currentTile.Occupant
		_tileData.pushStack.append(newResult)

	var directionVector = GameSettingsTemplate.GetVectorFromDirection(_tileData.pushDirection)
	for i in range(0, _tileData.pushAmount):
		var nextTile = GetTile(currentTile.Position + directionVector)
		if nextTile == null:
			# Early exit - we're done
			return

		if Push(_tileData, nextTile, currentTile, _tileData.pushDirection):
			return

		# If we're here - the tile is free to push onto
		currentTile = nextTile

	# if we're here - than the push did not result in a collision
	if _tileData.pushStack.size() != 0:
		WalkBackPushStack(_tileData, currentTile, _tileData.pushDirection)

	pass

func Push(_tileData : TileTargetedData, _nextTile : Tile, _currentTile : Tile, _direction : GameSettingsTemplate.Direction):
	# Check wall first, then occupant
	if _nextTile.IsWall || (_nextTile.Occupant != null && _nextTile.Occupant.Template.GridSize > 1):
		# It's up in the air as to if this should even be set if there's nothing in the push stack
		# We'll see if it affects anything
		_tileData.pushCollision = _nextTile

		if _tileData.pushStack.size() != 0:
			# Walk back the push stack - placing units where they're supposed to be
			WalkBackPushStack(_tileData, _currentTile, _direction)

		return true

	# Check if the next tile has an occupant
	if _nextTile.Occupant != null:
		if _tileData.pushStack.size() < _tileData.carryLimit:
			var newResult = PushResult.new()
			newResult.Subject = _nextTile.Occupant
			_tileData.pushStack.append(newResult)
		else:
			# We already have a subject we're pushing and we've hit another subject
			# Exit now
			_tileData.pushCollision = _nextTile

			WalkBackPushStack(_tileData, _currentTile, _direction)
			return true

	return false

func WalkBackPushStack(_tileData : TileTargetedData, _currentTile : Tile, _direction : GameSettingsTemplate.Direction):
	# The last unit added to the push stack gets the current tile
	# Work backwards from there to determine who ends up where
	var index = _tileData.pushStack.size() - 1
	var inverseDirection = GameSettingsTemplate.GetInverseVectorFromDirection(_direction)
	while (index >= 0):
		var inverseIndex = (_tileData.pushStack.size() - 1) - index
		_tileData.pushStack[index].ResultingTile = GetTile(_currentTile.Position + (inverseDirection * inverseIndex))
		index -= 1


func GetBestTileFromDirection(_origin : Tile, _direction : GameSettingsTemplate.Direction, _filteredList : Array[Tile]):
	var listCopy = _filteredList.duplicate()
	var originIndex = listCopy.find(_origin)
	if originIndex != -1:
		listCopy.remove_at(originIndex)

	match _direction:
		GameSettingsTemplate.Direction.Up:
			listCopy = listCopy.filter(func(tile : Tile): return tile.Position.y < _origin.Position.y)
		GameSettingsTemplate.Direction.Right:
			listCopy = listCopy.filter(func(tile : Tile): return tile.Position.x > _origin.Position.x)
		GameSettingsTemplate.Direction.Down:
			listCopy = listCopy.filter(func(tile : Tile): return tile.Position.y > _origin.Position.y)
		GameSettingsTemplate.Direction.Left:
			listCopy = listCopy.filter(func(tile : Tile): return tile.Position.x < _origin.Position.x)

	if listCopy.size() == 0:
		return null

	var smallestTileBasedOnDistance : Tile = listCopy[0]
	var dst = GetManhattanDistance(smallestTileBasedOnDistance.Position, _origin.Position)
	for t in listCopy:
		var newDST = GetManhattanDistance(t.Position, _origin.Position)
		if newDST < dst:
			dst = newDST
			smallestTileBasedOnDistance = t

	return smallestTileBasedOnDistance


func GetManhattanDistance(_gridPosition1 : Vector2i, _gridPosition2 : Vector2i):
	var x = abs(_gridPosition1.x - _gridPosition2.x)
	var y = abs(_gridPosition1.y - _gridPosition2.y)
	return x + y




func ToJSON():
	var dict = {
		"Width" = Width,
		"Height" = Height,
		"CellSize" = CellSize,
		"GridArr" = PersistDataManager.ArrayToJSON(GridArr)
	}
	return dict

static func FromJSON(_dict, _map : Map):
	var newGrid = Grid.new()
	newGrid.map = _map
	newGrid.Width = _dict["Width"]
	newGrid.Height = _dict["Height"]
	newGrid.CellSize = _dict["CellSize"]

	var canvasMod = GameManager.GameSettings.GridModulatePrefab.instantiate() as TileMapLayer
	_map.add_child(canvasMod)

	var gridArrData = PersistDataManager.JSONToArray(_dict["GridArr"], Callable.create(Tile, "FromJSON"))
	newGrid.GridArr.assign(gridArrData)
	for t in newGrid.GridArr:
		if t.TerrainDestroyed:
			newGrid.DestroyTerrain(t, false)

		canvasMod.set_cell(t.Position, UITILEATLAS, BASEBLACKTILE)

	newGrid.RefreshShroud()

	return newGrid
