extends Node2D
class_name Map

enum MAPSTATE { PreMap, Combat, PostMap }

@export_category("Meta Data")
@export var GridSize = Vector2i(22 , 15)
@export var CameraStart : Vector2
@export var TileSize = 64

@export_category("Layers")
@export var tilemap_bg : TileMapLayer
@export var tilemap_main : TileMapLayer
@export var tilemap_threat : TileMapLayer
@export var tilemap_UI : TileMapLayer

@export_category("Objectives")
@export var WinCondition : MapObjective
@export var OptionalObjectives : Array[ObjectiveReward]


@export_category("Parents")
@export var squadParent : Node2D
@export var StartingPositionsParent : Node2D
@export var SpawnersParent : Node2D

var MapState : MapStateBase
var CurrentCampaign : CampaignTemplate

var teams = {}
var unitsKilled = {}
var playercontroller : PlayerController
var currentTurn = GameSettingsTemplate.TeamID

var rng : RandomNumberGenerator
var grid : Grid
var turnCount : int
var formationSelected = false
var startingPositions : Array[Vector2i]
var spawners : Array[SpawnerBase]

var combatLedger

func _ready():
	PreInitialize()
	if get_parent() == get_tree().root:
		# I'm running the show by myself, so initialize a squad
		InitializeStandalone()

func PreInitialize():
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

func _process(_delta):
	if MapState != null:
		MapState.Update(_delta)

	if WinCondition != null && MapState is CombatState:
		if WinCondition.CheckObjective(self):
			# Wait for everything to resolve first
			if GlobalStackClear():
				ChangeMapState(VictoryState.new())

func InitializeFromCampaign(_campaign : CampaignTemplate, _roster : Array[UnitInstance], _rngSeed : int):
	rng = RandomNumberGenerator.new()
	rng.seed = _rngSeed
	CurrentCampaign = _campaign

	InitializeGrid()

	for i in range(0, _roster.size()):
		if i < startingPositions.size():
			InitializeUnit(_roster[i], startingPositions[i], GameSettingsTemplate.TeamID.ALLY)

	InitializePlayerController()
	ChangeMapState(PreMapState.new())

func GlobalStackClear():
	var stackFree = true
	for team in teams:
		for unit in teams[team]:
			if unit == null:
				continue

			# also don't end the turn if there is a unit with something on its stack
			if !unit.IsStackFree:
				stackFree = false
	return stackFree && !(playercontroller.ControllerState is ActionExecutionState)

func InitializeStandalone():
	# the campaign should initialize this
	rng = RandomNumberGenerator.new()

	# make the grid first so that we know where the starting positions are
	InitializeGrid()

	var ui = GameManager.AlphaUnitSelection.instantiate()
	ui.Initialize(startingPositions.size())
	ui.OnRosterSelected.connect(OnRosterTemplatesSelected)
	add_child(ui)

	#waits until that UI is closed, when the squad is all selected
	await ui.OnRosterSelected

	InitializePlayerController()
	ChangeMapState(PreMapState.new())

# only used by the roster selection ui. In normal campaign initialization, the UnitInstances should already be created
func OnRosterTemplatesSelected(_roster : Array[UnitTemplate]):
	for i in range(0, _roster.size()):
		if i < startingPositions.size():
			var unit = CreateUnit(_roster[i])
			InitializeUnit(unit, startingPositions[i], GameSettingsTemplate.TeamID.ALLY)


func InitializePlayerController():
	playercontroller = GameManager.GameSettings.PlayerControllerPrefab.instantiate()
	add_child(playercontroller)
	playercontroller.Initialize(self)

func CreateUnit(_unitTemplate : UnitTemplate, _levelOverride : int = 0):
	var unitInstance = GameManager.UnitSettings.UnitInstancePrefab.instantiate() as UnitInstance
	unitInstance.Initialize(_unitTemplate, _levelOverride)
	return unitInstance

func InitializeUnit(_unitInstance : UnitInstance, _position : Vector2i, _allegiance : GameSettingsTemplate.TeamID):
	_unitInstance.AddToMap(self, _position, _allegiance)
	grid.SetUnitGridPosition(_unitInstance, _position, true)
	AddUnitToRoster(_unitInstance, _allegiance)


func AddUnitToRoster(_unitInstance : UnitInstance, _allegiance : GameSettingsTemplate.TeamID):
	if teams.has(_allegiance):
		teams[_allegiance].append(_unitInstance)
	else:
		teams[_allegiance] = [] as Array[UnitInstance]
		teams[_allegiance].append(_unitInstance)


func InitializeGrid():
	grid = Grid.new()
	grid.Init(GridSize.x, GridSize.y, self, TileSize)


func ChangeMapState(_newState : MapStateBase):
	if MapState != null:
		MapState.Exit()

	MapState = _newState
	MapState.Enter(self, playercontroller)

func OnUnitDeath(_unitInstance : UnitInstance):
	var indexOf = teams[_unitInstance.UnitAllegiance].find(_unitInstance, 0)
	if indexOf >= 0:
		teams[_unitInstance.UnitAllegiance].remove_at(indexOf)

		if teams[_unitInstance.UnitAllegiance].size() == 0:
			teams.erase(_unitInstance.UnitAllegiance)

	if unitsKilled.has(_unitInstance.Template):
		unitsKilled[_unitInstance.Template] += 1
	else:
		unitsKilled[_unitInstance.Template] = 1

	RemoveUnitFromMap(_unitInstance)

# This can be called outside of unit death for units that are escaping
func RemoveUnitFromMap(_unitInstance : UnitInstance):
	# Collect the reference before hand
	var tile = _unitInstance.CurrentTile
	tile.Occupant = null
	_unitInstance.queue_free()

	grid.RefreshTilesCollision(tile, currentTurn)

func GetUnitsOnTeam(_teamBitMask : int):
	var returnUnits : Array[UnitInstance] = []
	for keyPair in teams:
		if keyPair & _teamBitMask:
			for units in teams[keyPair]:
				if units == null:
					continue
				returnUnits.append(units)

	return returnUnits


func GetClosestUnitToUnit(_currentUnit : UnitInstance, _targetTeam : int):
	var allUnitsAbleToBeTargeted = GetUnitsOnTeam(_targetTeam)
	var maxDistance = 1000000
	var targetUnit
	for unit in allUnitsAbleToBeTargeted:
		var path = grid.GetPathBetweenTwoUnits(_currentUnit, unit)
		if path.size() < maxDistance && path.size() != 0: # Check against 0, because 0 means you can't path there
			maxDistance = path.size()
			targetUnit = unit
	return targetUnit

func RefreshThreat():
	if grid.ShowingThreat && playercontroller.ControllerState.CanShowThreat():
		grid.RefreshThreat(GetUnitsOnTeam(GameSettingsTemplate.TeamID.ENEMY))

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mousePos = get_global_mouse_position()
		var tile_pos = tilemap_main.local_to_map(mousePos)
		OnTileClicked(tile_pos)

func OnTileClicked(a_tilePosition : Vector2i) :
	if grid.Pathfinding.is_in_bounds(a_tilePosition.x, a_tilePosition.y) :
		print_debug("Tile Position(", a_tilePosition.x, ",", a_tilePosition.y, ") - Is Solid ", grid.Pathfinding.is_point_solid(a_tilePosition))
		var tile = grid.GetTile(a_tilePosition)
		if tile != null:
			grid.ModifyTileHealth(-100, tile)
	else :
		print_debug("Click was not in pathfinding bounds")
