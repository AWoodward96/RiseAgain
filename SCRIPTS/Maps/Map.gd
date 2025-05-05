extends Node2D
class_name Map

static var Current : Map

const SUBBGLAYER : int = -6
const BGLAYER : int = -5
const MAINLAYER : int = -5
const EXTRALAYER : int = -4
const UILAYER : int = -3
const THREATLAYER : int = 0
const FIRELAYER : int = 2

signal OnUnitDied(_unitInstance : UnitInstance, _context : DamageStepResult)
signal OnUnitTurnEnd(_unitInstance : UnitInstance)
signal OnTurnStart(_turn : GameSettingsTemplate.TeamID)

enum MAPSTATE { PreMap, Combat, PostMap }
enum MAPTYPE { Standard, Campsite, Event }

@export_category("Meta Data")
@export var mapType : MAPTYPE
@export var GridSize = Vector2i(22 , 15)
@export var CameraStart : Vector2
@export var TileSize = 64
@export var AutosaveEnabled : bool = true
@export var Biome : BiomeData

@export_category("Layers")
@export var tilemap_bg : TileMapLayer
@export var tilemap_water : TileMapLayer
@export var tilemap_main : TileMapLayer
@export var tilemap_threat : TileMapLayer
@export var tilemap_fire : TileMapLayer
@export var tilemap_UI : TileMapLayer

@export_category("Objectives")
@export var WinCondition : MapObjective
@export var OptionalObjectives : Array[ObjectiveReward]

@export_category("Map Cutscenes")
@export var PreMapCutscene : CutsceneTemplate

@export_category("Parents")
@export var squadParent : Node2D
@export var StartingPositionsParent : Node2D
@export var SpawnersParent : Node2D

var gridEntityParent : Node2D # Gets created at runtime

var PersistedMapState : String
var MapState : MapStateBase
var CurrentCampaign : Campaign

var teams = {}
var enemyUnitsKilled = {}
var playercontroller : PlayerController
var currentTurn : GameSettingsTemplate.TeamID = GameSettingsTemplate.TeamID.ALLY
var currentBiome : BiomeData

var mapRNG : DeterministicRNG
var grid : Grid
var turnCount : int
var startingPositions : Array[Vector2i]
var spawners : Array[SpawnerBase]
var gridEntities : Array[GridEntityBase]

var standaloneUnitSelectionUI


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

	if tilemap_water != null: tilemap_water.z_index = SUBBGLAYER
	if tilemap_bg != null: tilemap_bg.z_index = BGLAYER
	if tilemap_fire != null: tilemap_fire.z_index = FIRELAYER
	if tilemap_main != null: tilemap_main.z_index = MAINLAYER
	if tilemap_UI != null: tilemap_UI.z_index = UILAYER
	if tilemap_threat != null: tilemap_threat.z_index = THREATLAYER

	if Biome != null:
		Biome.UpdateBiomeAudio()

	if PreMapCutscene != null:
		CutsceneManager.QueueCutscene(PreMapCutscene)

func _process(_delta):
	if MapState != null:
		MapState.Update(_delta)

	if mapType == MAPTYPE.Standard:
		# To stop repeatedly going to victory or loss state
		if MapState is CombatState:
			if WinCondition != null:
				if !CutsceneManager.BlockWincon && (WinCondition.CheckObjective(self) || CSR.AutoWin):
					# Wait for everything to resolve first
					if GlobalStackClear():
						if CSR.AutoWin:
							CSR.AutoWin = false
						ChangeMapState(VictoryState.new())

			if GameManager.GameSettings.DefaultLossState.CheckObjective(self) || CSR.AutoLose:
				ChangeMapState(LossState.new())


func InitializeFromCampaign(_campaign : Campaign, _roster : Array[UnitInstance], _rngSeed : int):
	mapRNG = DeterministicRNG.Construct(_rngSeed)
	Current = self
	CurrentCampaign = _campaign

	InitializeGrid()

	for i in range(0, _roster.size()):
		if i < startingPositions.size():
			InitializeUnit(_roster[i], startingPositions[i], GameSettingsTemplate.TeamID.ALLY)

	InitializePlayerController()

	match mapType:
		MAPTYPE.Standard:
			ChangeMapState(PreMapState.new())
		MAPTYPE.Campsite:
			ChangeMapState(CampsiteState.new())


func ResumeFromCampaign(_campaign : Campaign):
	CurrentCampaign = _campaign
	Current = self
	InitializePlayerController()
	match mapType:
		MAPTYPE.Standard:
			match PersistedMapState:
				"CombatState":
					var combatState = CombatState.new()
					combatState.InitializeFromPersistence(self, playercontroller)
					MapState = combatState
					pass
				"PreMapState":
					var premapState = PreMapState.new()
					# Yes this is different. The real Enter method spawns all of the enemies
					# so this should NOT do that
					premapState.InitializeFromPersistence(self, playercontroller)
					MapState = premapState


		MAPTYPE.Campsite:
			ChangeMapState(CampsiteState.new())

	for spawner in spawners:
		spawner.hide()

	for startingP in StartingPositionsParent.get_children():
		startingP.hide()


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
	Current = self
	mapRNG = DeterministicRNG.Construct()

	# make the grid first so that we know where the starting positions are
	InitializeGrid()

	standaloneUnitSelectionUI = UIManager.AlphaUnitSelection.instantiate()
	standaloneUnitSelectionUI.Initialize(startingPositions.size())
	standaloneUnitSelectionUI.OnRosterSelected.connect(OnRosterTemplatesSelected)
	add_child(standaloneUnitSelectionUI)

	#waits until that UI is closed, when the squad is all selected
	await standaloneUnitSelectionUI.OnRosterSelected

	InitializePlayerController()

	match mapType:
		MAPTYPE.Standard:
			ChangeMapState(PreMapState.new())
		MAPTYPE.Campsite:
			ChangeMapState(CampsiteState.new())


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

func CreateUnit(_unitTemplate : UnitTemplate, _levelOverride : int = 0, _healthPerc : float = 1):
	var unitInstance = GameManager.UnitSettings.UnitInstancePrefab.instantiate() as UnitInstance
	unitInstance.Initialize(_unitTemplate, _levelOverride, _healthPerc)
	return unitInstance

func AddGridEntity(_gridEntity : GridEntityBase):
	if _gridEntity != null:
		gridEntities.append(_gridEntity)

	if gridEntityParent == null:
		gridEntityParent = Node2D.new()
		gridEntityParent.name = "GridEntityParent"
		add_child(gridEntityParent)

	gridEntityParent.add_child(_gridEntity)

func InitializeUnit(_unitInstance : UnitInstance, _position : Vector2i, _allegiance : GameSettingsTemplate.TeamID, _healthPerc : float = 1):
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

func OnUnitDeath(_unitInstance : UnitInstance, _context : DamageStepResult):
	var indexOf = teams[_unitInstance.UnitAllegiance].find(_unitInstance, 0)
	if indexOf >= 0:
		teams[_unitInstance.UnitAllegiance].remove_at(indexOf)

		if teams[_unitInstance.UnitAllegiance].size() == 0:
			teams.erase(_unitInstance.UnitAllegiance)

	if _unitInstance.UnitAllegiance == GameSettingsTemplate.TeamID.ENEMY:
		if enemyUnitsKilled.has(_unitInstance.Template):
			enemyUnitsKilled[_unitInstance.Template] += 1
		else:
			enemyUnitsKilled[_unitInstance.Template] = 1

	if _context != null && _context.AbilityData != null:
		_context.AbilityData.kills += 1

	# despawn any grid entities that this unit is the owner of
	for ge in gridEntities:
		if ge != null && ge.Source != null && ge.Source == _unitInstance:
			ge.Expired = true
	RemoveExpiredGridEntities()

	RemoveUnitFromMap(_unitInstance)
	OnUnitDied.emit(_unitInstance, _context)
	RefreshThreat()

func RemoveExpiredGridEntities():
	for i in range(gridEntities.size() - 1, -1, -1):
		var cur = gridEntities[i]
		if cur == null:
			gridEntities.remove_at(i)
			continue

		if gridEntities[i].Expired:
			cur.Exit()
			cur.queue_free()
			gridEntities.remove_at(i)

# This can be called outside of unit death for units that are escaping
func RemoveUnitFromMap(_unitInstance : UnitInstance):
	_unitInstance.visible = false

	await _unitInstance.IsStackFree

	# Some units are bigger than one tile big - we need to clear those tiles
	var unitSize = _unitInstance.Template.GridSize
	for i in range(0, unitSize):
		for j in range(0, unitSize):
			var offsetPosition = _unitInstance.GridPosition + Vector2i(i,j)
			var tile = grid.GetTile(offsetPosition)
			if tile != null && tile.Occupant == _unitInstance:
				tile.Occupant = null

	_unitInstance.queue_free()

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
	# this eats button inputs funnily enough, so the CSR menu wont work if this is commented in
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mousePos = get_global_mouse_position()
		var tile_pos = tilemap_main.local_to_map(mousePos)
		OnTileClicked(tile_pos)

func OnTileClicked(a_tilePosition : Vector2i) :
	if grid.PositionIsInGridBounds(a_tilePosition) :
		var tile = grid.GetTile(a_tilePosition)
		if tile != null:
			print_debug("Tile Clicked(", a_tilePosition.x, ",", a_tilePosition.y, ") - Is Wall ", tile.IsWall)
			if tile.Occupant != null:
				print_debug("Tile Occupant: " + str(tile.Occupant.Template.DebugName))

	else :
		print_debug("Click was not in pathfinding bounds")

func Save():
	var mapJSON = ToJSON()
	var map_save_file = FileAccess.open(PersistDataManager.MAP_FILE, FileAccess.WRITE)
	var map_stringify = JSON.stringify(mapJSON, "\t")
	map_save_file.store_line(map_stringify)

	# then save the grid as a json
	var gridJSON = grid.ToJSON()
	var grid_save_file = FileAccess.open(PersistDataManager.MAP_GRID_FILE, FileAccess.WRITE)
	var grid_stringify = JSON.stringify(gridJSON, "\t")
	grid_save_file.store_line(grid_stringify)
	pass

func ToJSON():
	# LETS FUCKING GOOOOOOO
	var dict = {
		"prefabpath" = self.scene_file_path,
		"currentTurn" = currentTurn,
		"mapRNG" = mapRNG.ToJSON(),
		"turnCount" = turnCount,
		"MapState" = MapState.ToJSON(),
		"gridEntities" = PersistDataManager.ArrayToJSON(gridEntities),
	}

	var teamsJSONDict : Dictionary = {}
	for t in teams:
		# Teams is a dictionary containing arrays
		teamsJSONDict[t] = PersistDataManager.ArrayToJSON(teams[t])

	dict["teams"] = teamsJSONDict

	# convert the kills dict to a storable json
	var killsDict = {}
	for keypair in enemyUnitsKilled:
		if keypair == null:
			continue
		killsDict[keypair.resource_path] = enemyUnitsKilled[keypair]
	dict["enemyUnitsKilled"] = killsDict

	return dict

static func FromJSON(_dict : Dictionary, _assignedCampaign : Campaign):
	# This should make it so that everything that's exported - doesn't need to be stored from JSON
	var mapscene = load(_dict["prefabpath"]) as PackedScene
	var map = mapscene.instantiate() as Map
	Map.Current = map
	map.CurrentCampaign = _assignedCampaign
	map.currentTurn = _dict["currentTurn"]
	map.mapRNG = DeterministicRNG.FromJSON(_dict["mapRNG"])
	map.turnCount = int(_dict["turnCount"])

	map.PersistedMapState = _dict["MapState"]

	# Get the grid data
	var parsedString = PersistDataManager.GetJSONTextFromFile(PersistDataManager.MAP_GRID_FILE)
	map.grid = Grid.FromJSON(parsedString, map)
	map.grid.map = map
	for t in map.grid.GridArr:
		if t.OnFire:
			map.grid.IgniteTile(t, t.FireLevel)

	# get units killed
	for keypair in _dict["enemyUnitsKilled"]:
		var template = load(keypair) as UnitTemplate
		map.enemyUnitsKilled[template] = _dict["enemyUnitsKilled"][keypair] # Disgusting

	# Load the units
	var storedTeamsDict = _dict["teams"]
	for t in storedTeamsDict:
		var assignMe : Array[UnitInstance]
		var unitData = PersistDataManager.JSONToArray(storedTeamsDict[t], Callable.create(UnitInstance, "FromJSON"))
		assignMe.assign(unitData)
		map.teams[int(t)] = assignMe

	# Move the units where they're supposed to go
	for t in map.teams:
		for unit : UnitInstance in map.teams[t]:
			unit.AddToMap(map, unit.GridPosition, unit.UnitAllegiance)
			map.grid.SetUnitGridPosition(unit, unit.GridPosition, true)
			unit.TurnStartTile = map.grid.GetTile(unit.GridPosition)

			if t == GameSettingsTemplate.TeamID.ALLY:
				_assignedCampaign.CurrentRoster.append(unit)


	# Initialize the Grid Entities Last
	var data = PersistDataManager.JSONToArray(_dict["gridEntities"], Callable.create(GridEntityBase, "FromJSON"))
	for d in data:
		map.AddGridEntity(d)

	return map
