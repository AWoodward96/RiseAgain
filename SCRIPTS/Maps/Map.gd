extends Node2D
class_name Map

static var Current : Map

const SUBBGLAYER : int = -6
const BGLAYER : int = -5
const MAINLAYER : int = -5
const DESTRUCTABLELAYER : int = 0
const EXTRALAYER : int = -4
const UILAYER : int = -3
const THREATLAYER : int = 0
const FIRELAYER : int = 2
const UI_LIGHTMASK : int = 20

signal OnUnitDied(_unitInstance : UnitInstance, _context : DamageStepResult)

@warning_ignore("unused_signal") # These are used in other classes as a bus
signal OnUnitTurnEnd(_unitInstance : UnitInstance)
@warning_ignore("unused_signal")
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
@export var RewardOverride : LootTable
@export var Par : int = 3


@export_category("Layers")
@export var tilemap_bg : TileMapLayer
@export var tilemap_water : TileMapLayer
@export var tilemap_main : TileMapLayer
@export var tilemap_destructable : TileMapLayer
@export var tilemap_threat : TileMapLayer
@export var tilemap_fire : TileMapLayer
@export var tilemap_UI : TileMapLayer
@export var has_destrutable_visible_obfuscation : bool = false # If true, then the Units

@export_category("Objectives")
@export var WinCondition : MapObjective
@export var OptionalObjectives : Array[ObjectiveReward]

@export_category("Map Cutscenes")
@export var PreMapCutscene : CutsceneTemplate
@export var PostMapCutscene : CutsceneTemplate

@export_category("Parents")
@export var squadParent : Node2D
@export var StartingPositionsParent : Node2D
@export var SpawnersParent : Node2D

var gridEntityParent : Node2D # Gets created at runtime
var trashCan : Node2D # Gets created at runtime

var PersistedMapState : String
var MapState : MapStateBase
var CurrentCampaign : Campaign
var EventComplete : bool = false

var teams = {}
var enemyUnitsKilled = {}
var playercontroller : PlayerController
var currentTurn : GameSettingsTemplate.TeamID = GameSettingsTemplate.TeamID.ALLY

var mapRNG : DeterministicRNG
var grid : Grid
var turnCount : int
var startingPositions : Array[Vector2i]
var spawners : Array[SpawnerBase]
var gridEntities : Array[GridEntityBase]
var passiveActionStack : Array[PassiveAbilityAction]
var currentPassiveAction : PassiveAbilityAction

var standaloneUnitSelectionUI

var PreTurnComplete : bool :
	get():
		if MapState is CombatState:
			return MapState.preTurnComplete
		else:
			return true

func _ready():
	PreInitialize()
	if get_parent() == get_tree().root:
		# I'm running the show by myself, so initialize a squad
		InitializeStandalone()

	if squadParent != null:
		squadParent.y_sort_enabled = true


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
	if tilemap_destructable != null :
		tilemap_destructable.z_index = DESTRUCTABLELAYER
		tilemap_destructable.y_sort_enabled = true
		y_sort_enabled = true

	if tilemap_UI != null:
		tilemap_UI.z_index = UILAYER
		tilemap_UI.light_mask = UI_LIGHTMASK # to keep light from affecting ui tiles

	if tilemap_threat != null:
		tilemap_threat.z_index = THREATLAYER
		tilemap_threat.light_mask = UI_LIGHTMASK # to keep light from affecting threat


	if Biome != null:
		if Biome.DirectionalLight != null:
			add_child(Biome.DirectionalLight.instantiate())

		if Biome.Particles != null:
			add_child(Biome.Particles.instantiate())

	AudioManager.UpdateBiomeData(Biome)


func _process(_delta):
	if !UpdatePassiveActions(_delta):
		return

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

func UpdatePassiveActions(_delta):
	if currentPassiveAction == null && passiveActionStack.size() != 0:
		# First wait for global stack clear
		if GlobalStackClear():
			currentPassiveAction = passiveActionStack.pop_front()

	if currentPassiveAction != null:
		if currentPassiveAction.TryExecute(_delta):
			if passiveActionStack.size() != 0:
				currentPassiveAction = passiveActionStack.pop_front()
				return false
			else:
				currentPassiveAction = null
				print("passive action complete")
		else:
			return false

	return true

func AppendPassiveAction(_action : PassiveAbilityAction):
	print("Passive Action Logged")
	passiveActionStack.append(_action)
	passiveActionStack.sort_custom(func(a : PassiveAbilityAction, b : PassiveAbilityAction): return a.priority > b.priority)

func QueueUnitForRemoval(_unitInstance : UnitInstance):
	if trashCan == null:
		trashCan = Node2D.new()
		trashCan.name = "Trash"
		add_child(trashCan)
		trashCan.visible = false

	# Actually, why queue-free the unit at all?
	_unitInstance.reparent(trashCan)
	pass

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
		MAPTYPE.Standard, MAPTYPE.Event:
			ChangeMapState(PreMapState.new())
		MAPTYPE.Campsite:
			ChangeMapState(CampsiteState.new())


func ResumeFromCampaign(_campaign : Campaign):
	CurrentCampaign = _campaign
	Current = self
	InitializePlayerController()
	match mapType:
		MAPTYPE.Standard, MAPTYPE.Event:
			match PersistedMapState:
				"CombatState":
					var combatState = CombatState.new()
					combatState.InitializeFromPersistence(self, playercontroller)
					MapState = combatState

					for startingP in StartingPositionsParent.get_children():
						startingP.hide()
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
		MAPTYPE.Standard, MAPTYPE.Event:
			ChangeMapState(PreMapState.new())
		MAPTYPE.Campsite:
			ChangeMapState(CampsiteState.new())

# only used by the roster selection ui. In normal campaign initialization, the UnitInstances should already be created
func OnRosterTemplatesSelected(_roster : Array[UnitTemplate], _levelOverride : int = 0):
	for i in range(0, _roster.size()):
		if i < startingPositions.size():
			var unit = CreateUnit(_roster[i], _levelOverride)
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
		gridEntityParent.y_sort_enabled = true
		add_child(gridEntityParent)

	gridEntityParent.add_child(_gridEntity)

func InitializeUnit(_unitInstance : UnitInstance, _position : Vector2i, _allegiance : GameSettingsTemplate.TeamID, _healthPerc : float = 1, _extraHealthBars : int = 0):
	_unitInstance.AddToMap(self, _position, _allegiance, _extraHealthBars)
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

	if Biome != null:
		grid.CanvasModLayer.material.set_shader_parameter("grid_color", Biome.GridColor)

func ChangeMapState(_newState : MapStateBase):
	if MapState != null:
		MapState.Exit()

	MapState = _newState
	MapState.Enter(self, playercontroller)

func OnUnitDeath(_unitInstance : UnitInstance, _context : DamageStepResult):
	if !teams.has(_unitInstance.UnitAllegiance) || _unitInstance.IsDying:
		return

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

	if _context != null:
		if _context.AbilityData != null:
			_context.AbilityData.kills += 1

		if _context.Source != null && _context.Source.currentHealth > 0 && _context.Source.UnitAllegiance == GameSettingsTemplate.TeamID.ALLY:
			# Add item drops
			for item in _unitInstance.ItemSlots:
				if item != null:
					_context.Source.QueueAcquireLoot(item)

			# add resource gain
			if _unitInstance.UnitAllegiance == GameSettingsTemplate.TeamID.ENEMY && _unitInstance.Template.ResourceDrops.size() != 0:
				# remember camera space != global space. So convert this tile position to screen space before passing it in to the function that's gonna
				# create the pips on the globa ui
				var burstPosition = _unitInstance.CurrentTile.GlobalPosition
				var cameraPosition = playercontroller.camera.position - (playercontroller.camera.get_viewport_rect().size / 2)
				burstPosition -= cameraPosition

				PersistDataManager.universeData.AddResources(_unitInstance.Template.ResourceDrops, burstPosition)

	# despawn any grid entities that this unit is the owner of
	RemoveEntitiesOwnedByUnit(_unitInstance)

	# should happen before removal from the map for deathrattle effects
	OnUnitDied.emit(_unitInstance, _context)
	RemoveUnitFromMap(_unitInstance)
	RefreshThreat()

func RemoveEntitiesOwnedByUnit(_unitInstance : UnitInstance):
	for ge in gridEntities:
		if ge != null && ge.Source != null && ge.Source == _unitInstance:
			ge.Expired = true
	RemoveExpiredGridEntities()

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

func RemoveGridEntity(_gridEntity : GridEntityBase):
	var found = gridEntities.find(_gridEntity)
	if found != -1:
		gridEntities[found].Exit()
		gridEntities[found].queue_free()
		gridEntities.remove_at(found)

# This can be called outside of unit death for units that are escaping
func RemoveUnitFromMap(_unitInstance : UnitInstance, is_death : bool = true):

	await _unitInstance.IsStackFree

	# Some units are bigger than one tile big - we need to clear those tiles
	var unitSize = _unitInstance.Template.GridSize
	for i in range(0, unitSize):
		for j in range(0, unitSize):
			var offsetPosition = _unitInstance.GridPosition + Vector2i(i,j)
			var tile = grid.GetTile(offsetPosition)
			if tile != null && tile.Occupant == _unitInstance:
				tile.Occupant = null

	if !is_death:
		_unitInstance.queue_free()
	else:
		_unitInstance.PlayDeathAnimation()

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

func TryAddItemToConvoy(_item : Item):
	if CurrentCampaign != null:
		CurrentCampaign.Convoy.AddToConvoy(_item)

func _input(event):
	# this eats button inputs funnily enough, so the CSR menu wont work if this is commented in
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if tilemap_main != null:
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
