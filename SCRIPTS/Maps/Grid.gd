class_name Grid

const THREATLAYER = 1
const ACTIONOPTIONSLAYER = 2
const UITILEATLAS = 2
const ATTACKTILE = Vector2i(2,0)
const RANGETILE = Vector2i(1,0)
const MOVETILE = Vector2i(0,0)
const THREATTILE_1 = Vector2i(0,1)
const THREATTILE_2 = Vector2i(1,1)
const THREATTILE_3 = Vector2i(2,1)
const NEIGHBORS = [Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0)]

var GridArr : Array[Tile]
var Width: int
var Height: int
var Pathfinding : AStarGrid2D
var map : Map
var CellSize : int
var ShowingThreat : bool

var StartingPositions : Array[Vector2i]


func Init(_width : int, _height : int, _map : Map, _cell_size : int):
	Width = _width
	Height = _height
	CellSize = _cell_size
	map = _map

	# pre-initialize the Pathfinding data
	Pathfinding = AStarGrid2D.new()
	Pathfinding.region = Rect2i(0, 0, Width, Height)
	Pathfinding.cell_size = Vector2(CellSize, CellSize)
	Pathfinding.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	Pathfinding.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	Pathfinding.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	Pathfinding.update() # NOTE: calling update clears all solid data. DO NOT CALL THIS AGAIN

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
				GridArr[index].Killbox = bg_data.get_custom_data("Killbox")

			if map.tilemap_water != null:
				var water_data = map.tilemap_water.get_cell_tile_data(Vector2i(x,y))
				if water_data != null:
					GridArr[index].Killbox = GridArr[index].Killbox || water_data.get_custom_data("Killbox")

			var main_data = map.tilemap_main.get_cell_tile_data(Vector2i(x,y))
			if main_data:
				if main_data.get_collision_polygons_count(0) > 0 :
					GridArr[index].IsWall = true

				var health = main_data.get_custom_data("Health")
				if health > 0:
					GridArr[index].Health = health
					GridArr[index].MaxHealth = health

			Pathfinding.set_point_solid(Vector2i(x,y), GridArr[index].Killbox || GridArr[index].IsWall)

func RefreshGridForTurn(_allegience : GameSettingsTemplate.TeamID, _flying : bool = false):
	for x in Width:
		for y in Height:
			var index = y * Width + x
			var currentTile = GridArr[index]
			RefreshTilesCollision(currentTile, _allegience, _flying)

func RefreshTilesCollision(_tile : Tile, _allegience : GameSettingsTemplate.TeamID, _flying : bool = false):
	if _tile == null:
		return

	var x = _tile.Position.x
	var y = _tile.Position.y
	var main_data = map.tilemap_main.get_cell_tile_data(Vector2i(x,y))
	var bg_data = map.tilemap_bg.get_cell_tile_data(Vector2i(x,y))

	Pathfinding.set_point_solid(Vector2i(x,y), false)
	_tile.IsWall = false

	Pathfinding.set_point_weight_scale(Vector2i(x,y), 1)
	if main_data:
		if main_data.get_collision_polygons_count(0) > 0 :
			_tile.IsWall = true

	if bg_data != null:
		_tile.Killbox = bg_data.get_custom_data("Killbox")

	Pathfinding.set_point_solid(Vector2i(x,y), (_tile.IsWall || _tile.Killbox) && !_flying)

	if _tile.Occupant != null:
		if _tile.Occupant.UnitAllegiance != _allegience:
			Pathfinding.set_point_solid(Vector2i(x,y), true)
		else:
			Pathfinding.set_point_weight_scale(Vector2i(x,y), 2)



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
	var workingList : Array[Tile]
	for u in _units:
		if u == null || u.currentHealth <= 0:
			continue

		var movement = GetCharacterMovementOptions(u, false)
		movement = GetUniqueTiles(movement)

		var unitRange = u.GetEffectiveAttackRange()
		var threatRange = GetCharacterAttackOptions(u, movement, unitRange, false)
		threatRange = GetUniqueTiles(threatRange)
		workingList.append_array(threatRange)

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

	map.tilemap_UI.clear()

func ShowActions() :
	for n in GridArr :
		if n.Occupant != null :
			continue

		if n.InRange :
			map.tilemap_UI.set_cell(n.Position, UITILEATLAS, RANGETILE)

		if n.CanMove :
			map.tilemap_UI.set_cell(n.Position, UITILEATLAS, MOVETILE)
			continue

		if n.CanAttack :
			map.tilemap_UI.set_cell(n.Position, UITILEATLAS, ATTACKTILE)



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
	frontier.append(GridArr[startingIndex])
	visited[GridArr[startingIndex]] = 0

	var currentMovement = 0
	while !frontier.is_empty():
		var current = frontier.pop_front() as Tile
		if _markTiles:
			current.CanMove = true

		if visited[current] > movement:
			break

		for neigh in NEIGHBORS:
			var neighborLocation = current.Position + neigh
			var tile = GetTile(neighborLocation)
			if tile == null:
				continue

			if visited.has(tile):
				continue

			if unitHasFlying || !Pathfinding.is_point_solid(neighborLocation):
				var occupant = tile.Occupant
				if (occupant == null) || (occupant != null && occupant.UnitAllegiance == _unit.UnitAllegiance):
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


func SetUnitGridPosition(_unit : UnitInstance, _newPosition : Vector2i, _updateWorldPosition : bool) :
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


	if unitSize != 1:
		print("ignoreme")

	position = _newPosition
	for i in range(0, unitSize):
		for j in range(0, unitSize):
			position = _newPosition + Vector2i(i,j)
			var newIndex = GetGridArrIndex(position)
			if GridArr[newIndex].Occupant == null:
				GridArr[newIndex].Occupant = _unit

	_unit.CurrentTile = GridArr[GetGridArrIndex(_newPosition)]


func GetGridArrIndex(_pos : Vector2i):
	return _pos.y * Width + _pos.x

func GetTile(_pos : Vector2i):
	if _pos.y < 0 || _pos.x < 0 || _pos.x >= Width || _pos.y >= Height:
		return null

	var index = GetGridArrIndex(_pos)
	if index < 0 || index >= GridArr.size():
		return null
	return GridArr[index]

func GetAdjacentTiles(_tile : Tile):
	var arr : Array[Tile]
	for n in NEIGHBORS:
		var t = GetTile(_tile.Position + n)
		if t != null:
			arr.append(t)
	return arr

func GetCharacterAttackOptions(_unit : UnitInstance, _workingList : Array[Tile], _attackRange : Vector2i, _markTiles : bool = true) :
	var returnArr : Array[Tile] = []
	for n in _workingList :
		for x in range(-_attackRange.y, _attackRange.y + 1) :
			for y in range(-_attackRange.y, _attackRange.y + 1) :
				if (x == 0 && y == 0) || (_unit.GridPosition == n.Position + Vector2i(x,y)) :
					continue

				var position = n.Position as Vector2 + Vector2(x,y)
				if (Pathfinding.is_in_bounds(position.x, position.y)):
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
			if Pathfinding.is_in_bounds(position.x, position.y):
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

	if _tile.Health <= 0:
		map.tilemap_main.set_cell(_tile.Position)
		RefreshTilesCollision(_tile, map.currentTurn as int)

		# We do it like this so that you can't retarget this tile anymore
		_tile.MaxHealth = 0
		_tile.Health = 0


func GetPathBetweenTwoUnits(_originUnit : UnitInstance, _destinationUnit : UnitInstance):
	# save whether or not the destination is solid.
	var destinationIsSolid = Pathfinding.is_point_solid(_destinationUnit.GridPosition)
	if destinationIsSolid:
		# set the destination as not solid before the calculation
		Pathfinding.set_point_solid(_destinationUnit.GridPosition, false)

	# do the calculation
	var path = Pathfinding.get_point_path(_originUnit.GridPosition, _destinationUnit.GridPosition)

	# and if it was solid before the calculation, reset it to being solid again for future calculations
	if destinationIsSolid:
		# and then reset the point to solid if it is
		Pathfinding.set_point_solid(_destinationUnit.GridPosition, true)

	return path

func PushCast(_tileData : TileTargetedData):
	if _tileData == null || _tileData.Tile == null:
		return

	if !_tileData.willPush:
		push_error("Attempting to pushcast with an invalid origin tile. Tile: " + str(_tileData.Tile.Position))

	var currentTile = _tileData.Tile

	# Check the origin tile for an occupant - if there's one there add them to the stack.
	if currentTile.Occupant != null:
		var newResult = PushResult.new()
		newResult.Subject = currentTile.Occupant
		_tileData.pushStack.append(newResult)

	var directionVector = GameSettingsTemplate.GetVectorFromDirection(_tileData.pushDirection)
	for i in range(0, _tileData.pushAmount):
		var nextTile = GetTile(currentTile.Position + directionVector)
		if nextTile == null:
			# Early exit - we're done
			_tileData.pushSelfResult = currentTile
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

	if _nextTile.IsWall:
		# It's up in the air as to if this should even be set if there's nothing in the push stack
		# We'll see if it affects anything
		_tileData.pushCollision = _nextTile

		if _tileData.pushStack.size() != 0:
			# Walk back the push stack - placing units where they're supposed to be
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
		# man I wish it was easier to do deprecating for loops

func GetManhattanDistance(_gridPosition1 : Vector2i, _gridPosition2 : Vector2i):
	var x = abs(_gridPosition1.x - _gridPosition2.x)
	var y = abs(_gridPosition1.y - _gridPosition2.y)
	return x + y
