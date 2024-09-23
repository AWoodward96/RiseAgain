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

			var main_data = map.tilemap_main.get_cell_tile_data(Vector2i(x,y))
			if main_data:
				if main_data.get_collision_polygons_count(0) > 0 :
					GridArr[index].IsWall = true

				var health = main_data.get_custom_data("Health")
				if health > 0:
					GridArr[index].Health = health

			Pathfinding.set_point_solid(Vector2i(x,y), GridArr[index].Killbox || GridArr[index].IsWall)

func RefreshGridForTurn(_allegience : GameSettingsTemplate.TeamID):
	for x in Width:
		for y in Height:
			var index = y * Width + x
			var currentTile = GridArr[index]
			RefreshTilesCollision(currentTile, _allegience)

func RefreshTilesCollision(_tile : Tile, _allegience : GameSettingsTemplate.TeamID):
	if _tile == null:
		return

	var x = _tile.Position.x
	var y = _tile.Position.y
	var main_data = map.tilemap_main.get_cell_tile_data(Vector2i(x,y))
	var bg_data = map.tilemap_bg.get_cell_tile_data(Vector2i(x,y))

	Pathfinding.set_point_solid(Vector2i(x,y), false)
	Pathfinding.set_point_weight_scale(Vector2i(x,y), 1)
	if main_data:
		if main_data.get_collision_polygons_count(0) > 0 :
			_tile.IsWall = true

	if bg_data != null:
		_tile.Killbox = bg_data.get_custom_data("Killbox")

	Pathfinding.set_point_solid(Vector2i(x,y), _tile.IsWall || _tile.Killbox)

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
	var workingList : Array[Tile] = []
	var startingIndex = _unit.GridPosition.y * Width + _unit.GridPosition.x
	frontier.append(GridArr[startingIndex])

	var movement = _unit.GetUnitMovement()
	for move in movement + 1: # +1 because for loops are not inclusive
		for current in frontier :
			if _markTiles:
				current.CanMove = true
			returnList.append(current)

			for neigh in NEIGHBORS:
				var neighborLocation = current.Position + neigh
				if Pathfinding.is_in_bounds(neighborLocation.x, neighborLocation.y) :
					var neighborIndex = neighborLocation.y * Width + neighborLocation.x
					if !Pathfinding.is_point_solid(neighborLocation):
						var occupant = GridArr[neighborIndex].Occupant
						if (occupant== null) || (occupant != null && occupant.UnitAllegiance == _unit.UnitAllegiance):
							workingList.append(GridArr[neighborIndex])

		frontier = workingList.duplicate(true)
		workingList.clear()

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
	var prevIndex = GetGridArrIndex(_unit.GridPosition)
	if GridArr[prevIndex].Occupant == _unit:
		GridArr[prevIndex].Occupant = null

	# update the physical location of the unit
	if _updateWorldPosition:
		_unit.global_position = _newPosition * CellSize

	_unit.GridPosition = _newPosition

	var newIndex = GetGridArrIndex(_newPosition)
	GridArr[newIndex].Occupant = _unit
	_unit.CurrentTile = GridArr[newIndex]


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

func GetManhattanDistance(_gridPosition1 : Vector2i, _gridPosition2 : Vector2i):
	var x = abs(_gridPosition1.x - _gridPosition2.x)
	var y = abs(_gridPosition1.y - _gridPosition2.y)
	return x + y
