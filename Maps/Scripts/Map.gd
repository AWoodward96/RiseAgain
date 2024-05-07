extends Node2D
class_name Map

enum MAPSTATE { PreMap, Combat, PostMap }
@export var GridSize = Vector2i(22 , 15)
@export var CameraStart : Vector2
@export var TileSize = 64


@onready var tilemap : TileMap = $Tilemap
@onready var squadParent = $Squads
@onready var StartingPositionsParent : Node2D = %StartingPositions
@onready var SpawnersParent : Node2D = %Spawners

var MapState : MapStateBase

var teams = {}
var playercontroller : PlayerController

var rng : RandomNumberGenerator
var grid : Grid
var turnCount : int
var formationSelected = false
var startingPositions : Array[Vector2i]
var spawners : Array[SpawnerBase]

func _ready():
	if get_parent() == get_tree().root:
		# I'm running the show by myself, so initialize a squad
		InitializeStandalone()

func _process(_delta):
	if MapState != null:
		MapState.Update(_delta)

func InitializeFromCampaign(_rngSeed : int):
	rng = RandomNumberGenerator.new()
	rng.seed = _rngSeed

	# TODO: Figure out where this actually deviates
	InitializeStandalone()

func InitializeStandalone():
	# make the grid first so that we know where the starting positions are
	InitializeGrid()

	var ui = GameManager.AlphaUnitSelection.instantiate()
	ui.Initialize(self)
	ui.OnRosterSelected.connect(OnRosterSelected)
	add_child(ui)

	#waits until that UI is closed, when the squad is all selected
	await ui.OnRosterSelected

	InitializePlayerController()
	ChangeMapState(PreMapState.new())

func OnRosterSelected(_roster : Array[UnitTemplate]):
	for i in range(0, _roster.size()):
		if i < startingPositions.size():
			InitializeUnit(_roster[i], startingPositions[i], GameSettings.TeamID.ALLY)

func InitializePlayerController():
	playercontroller = GameManager.GameSettings.PlayerControllerPrefab.instantiate()
	add_child(playercontroller)
	playercontroller.Initialize(self)

func InitializeUnit(_unitTemplate : UnitTemplate, _position : Vector2i, _allegiance : GameSettings.TeamID):
	var unitInstance = GameManager.UnitSettings.UnitInstancePrefab.instantiate() as UnitInstance
	unitInstance.Initialize(_unitTemplate, self, _position, _allegiance)
	squadParent.add_child(unitInstance)
	grid.SetUnitGridPosition(unitInstance, _position, true)
	AddUnitToRoster(unitInstance, _allegiance)
	return unitInstance

func AddUnitToRoster(_unitInstance : UnitInstance, _allegiance : GameSettings.TeamID):
	if teams.has(_allegiance):
		teams[_allegiance].append(_unitInstance)
	else:
		teams[_allegiance] = [] as Array[UnitInstance]
		teams[_allegiance].append(_unitInstance)


func InitializeGrid():
	grid = Grid.new()
	grid.Init(GridSize.x, GridSize.y, tilemap, TileSize)

	startingPositions.clear()
	for c in StartingPositionsParent.get_children():
		var helper = c as StartingPositionsHelper
		if helper != null:
			startingPositions.append(helper.Position)

	spawners.clear()
	for s in SpawnersParent.get_children():
		var spawner = s as SpawnerBase
		if spawner != null:
			spawners.append(spawner)

func ChangeMapState(_newState : MapStateBase):
	if MapState != null:
		MapState.Exit()

	MapState = _newState
	MapState.Enter(self, playercontroller)

func OnUnitDeath(_unitInstance : UnitInstance):
	var indexOf = teams[_unitInstance.UnitAllegiance].find(_unitInstance, 0)
	if indexOf >= 0:
		teams[_unitInstance.UnitAllegiance].remove_at(indexOf)

		#var hasUnitLeftOnTeam = false
		#for unit in teams[_unitInstance.UnitAllegiance]:
			#if unit != null && unit.currentHealth > 0:
				#hasUnitLeftOnTeam = true
#
		#if !hasUnitLeftOnTeam:
			#teams.erase(_unitInstance.UnitAllegiance)

		if teams[_unitInstance.UnitAllegiance].size() == 0:
			teams.erase(_unitInstance.UnitAllegiance)

	_unitInstance.queue_free()

func GetUnitsOnTeam(_teamBitMask : int):
	var returnUnits : Array[UnitInstance]
	for keyPair in teams:
		if keyPair & _teamBitMask:
			for units in teams[keyPair]:
				returnUnits.append(units)

	return returnUnits


func GetClosestUnitToUnit(_currentUnit : UnitInstance, _targetTeam : int):
	var allUnitsAbleToBeTargeted = GetUnitsOnTeam(_targetTeam)
	var maxDistance = 1000000
	var targetUnit
	for unit in allUnitsAbleToBeTargeted:
		var path = grid.GetPathBetweenTwoUnits(_currentUnit, unit)
		if path.size() < maxDistance:
			maxDistance = path.size()
			targetUnit = unit
	return targetUnit


#func _input(event):
	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#var mousePos = get_global_mouse_position()
		#var tile_pos = tilemap.local_to_map(mousePos)
		#OnTileClicked(tile_pos)


#func OnTileClicked(a_tilePosition : Vector2i) :
#
	#if grid.Pathfinding.is_in_bounds(a_tilePosition.x, a_tilePosition.y) :
		#print_debug("Is Solid ", grid.Pathfinding.is_point_solid(a_tilePosition))
	#else :
		#print_debug("Click was not in pathfinding bounds")
