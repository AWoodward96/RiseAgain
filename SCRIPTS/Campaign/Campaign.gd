extends Node2D
class_name Campaign

@export var current_map_parent : Node2D
@export var UnitHoldingArea : Node2D
@export var Convoy : ConvoyInstance

var currentCampaignTemplate : CampaignTemplate
var startingPOI : POI
var campaignLedger : Array[MapOption]
var currentPOI : POI

var currentMap : Map
var currentMapOption : MapOption
var currentMapBlock : MapBlock
var startingCampaignBlock : CampaignBlock
var currentCampaignBlock : CampaignBlock
var campaignBlockIndex : int
var teamSizeLimit = 3

var CampaignRng : DeterministicRNG

var StartingRosterTemplates : Array[UnitTemplate]
var CurrentRoster : Array[UnitInstance]
var DeadUnits : Array[UnitTemplate]

var campaignBlockMapIndex : int
var traversedCampaignBlocks : int
var resumingCampaign : bool = false
var currentLevelDifficulty : int
var alphaTeamSelection
var debug_leveloverride : int = 0

func InitializeNewCampaign(_campaignTemplate : CampaignTemplate, _startingRoster : Array[UnitTemplate]):
	StartingRosterTemplates = _startingRoster
	currentCampaignTemplate = _campaignTemplate
	campaignBlockMapIndex = 0
	traversedCampaignBlocks = 0
	teamSizeLimit = _campaignTemplate.startingTeamSizeLimit

	CampaignRng = DeterministicRNG.Construct()
	if currentCampaignTemplate.startingCampaignOptions.size() == 0:
		push_error("Campaign: " , name, " - does not have a starting campaign block and will not function.")
		return

	startingCampaignBlock = currentCampaignTemplate.GetInitialCampaignBlock(CampaignRng)
	currentCampaignBlock = startingCampaignBlock

	GetNextMapOption()

func StartCampaign():
	if currentCampaignTemplate == null:
		push_error("Attempting to start a campaign without preinitialization. No Current Campaign Template found")
		return

	UnitHoldingArea.visible = false

	if currentMap != null:
		if !resumingCampaign:
			CreateSquadInstance()
			StartMap()
		else:
			ResumeMap()

func GetNextMapOption():
	if campaignBlockMapIndex >= currentCampaignBlock.mapOptions.size():
		traversedCampaignBlocks += 1
		campaignBlockMapIndex = 0
		if currentCampaignTemplate.campaignBlockCap != -1 && traversedCampaignBlocks >= currentCampaignTemplate.campaignBlockCap && currentCampaignTemplate.campaignFinale != null:
			# We in endgame
			currentCampaignBlock = currentCampaignTemplate.campaignFinale
		else:
			if currentCampaignBlock.nextCampaignBlocks.size() == 0:
				# Well it's not.... easy to do anything here so just... end the map
				ReportCampaignResult(true)
				GameManager.ChangeGameState(BastionGameState.new(), null)
				return

			# if we're traversed each map option in the current campaign block, we need to initialize the next campaign block
			var nextIndex = CampaignRng.NextInt(0, currentCampaignBlock.nextCampaignBlocks.size() - 1)
			currentCampaignBlock = load(currentCampaignBlock.nextCampaignBlocks[nextIndex]) as CampaignBlock

	currentMapBlock = currentCampaignBlock.GetMapBlock(campaignBlockMapIndex)
	if currentMapBlock == null:
		push_error("Campaign: " , name, " - rolled a map block from the map options that is null somehow.")
		return

	currentMapOption = currentMapBlock.GetMapFromBlock()

	if currentMap != null:
		currentMap.queue_free()

	var newMap = currentMapOption.GetMap()
	if newMap == null:
		GetNextMapOption()
		return

	currentMap = newMap.instantiate() as Map
	pass

# Takes the current map option and starts it
func StartMap():
	if currentMap == null:
		return
#
	RefreshDifficultyLevel()

	# preinitialize collects up the spawners and the starting positions for usage
	# doesn't actually spawn anything yet
	currentMap.PreInitialize()

	# If there is no Roster, pull up the selection UI to force one. This should not occur in normal gameplay tbh
	#if CurrentRoster.size() == 0:
		#var ui = UIManager.AlphaUnitSelection.instantiate()
		#ui.Initialize(currentMap.startingPositions.size())
		#ui.OnRosterSelected.connect(OnRosterSelected)
		#add_child(ui)
#
		##waits until that UI is closed, when the squad is all selected
		#await ui.OnRosterSelected
		#CreateSquadInstance()

	var MapRNGSeed = CampaignRng.NextInt(0, 10000000)
	currentMap.InitializeFromCampaign(self, CurrentRoster, MapRNGSeed)

	if currentMap.get_parent() != current_map_parent:
		current_map_parent.add_child(currentMap)

	campaignLedger.append(currentMapOption)
	UIManager.HideLoadingScreen()
	PersistDataManager.SaveCampaign()

func ResumeMap():
	if currentMap == null:
		return

	# We may need to not do this, Ionno
	currentMap.PreInitialize()

	currentMap.ResumeFromCampaign(self)
	current_map_parent.add_child(currentMap)
	UIManager.HideLoadingScreen()

func CreateSquadInstance():
	for unit in StartingRosterTemplates:
		AddUnitToRoster(unit, debug_leveloverride)

func MapComplete():
	# Persist the current roster between maps
	RemoveEmptyRosterEntries()
	for unit in CurrentRoster:
		unit.OnMapComplete()
		unit.reparent(UnitHoldingArea)
		if unit.currentHealth > 0:
			PersistDataManager.universeData.GrantPrestiegeExp(unit.Template, GameManager.UnitSettings.PrestiegeGrantedPerMap)

	campaignBlockMapIndex += 1
	GetNextMapOption()

	if currentMap != null:
		StartMap()
	else:
		GameManager.ReturnToBastion()
	UIManager.HideLoadingScreen()

func UnitInjured(_unitInstance : UnitInstance):
	_unitInstance.reparent(UnitHoldingArea)
	_unitInstance.UpdateDerivedStats()
	_unitInstance.currentHealth = _unitInstance.maxHealth

func RegisterUnitDeath(_unitInstance : UnitInstance):
	DeadUnits.append(_unitInstance.Template)
	_unitInstance.queue_free()

func RemoveEmptyRosterEntries():
	var i = CurrentRoster.size() - 1
	while i >= 0:
		if not is_instance_valid(CurrentRoster[i]):
			CurrentRoster.remove_at(i)
		i -= 1

func GetMapRewardTable():
	if currentMap.RewardOverride != null:
		return currentMap.RewardOverride

	return GameManager.GameSettings.DefaultMapRewardTable

func OnRosterSelected(_roster : Array[UnitTemplate], _levelOverride : int):
	StartingRosterTemplates = _roster
	debug_leveloverride = _levelOverride

func AddUnitToRoster(_unitTemplate : UnitTemplate, _levelOverride = 0):
	var unitInstance = GameManager.UnitSettings.UnitInstancePrefab.instantiate() as UnitInstance
	unitInstance.Initialize(_unitTemplate, _levelOverride)
	CurrentRoster.append(unitInstance)
	UnitHoldingArea.add_child(unitInstance)
	return unitInstance

func IsUnitInRoster(_unitTemplate : UnitTemplate):
	for u in CurrentRoster:
		if u.Template == _unitTemplate:
			return true

	return false

func RefreshDifficultyLevel():
	for u in CurrentRoster:
		if u == null:
			continue

		if u.Level > currentLevelDifficulty:
			currentLevelDifficulty = u.Level

func ReportCampaignResult(_victory : bool):
	# Tell the Bastion Persist Data that they need to generate a new set of tavern dwellers
	GameManager.CurrentCampaign = null
	PersistDataManager.ClearCampaign()
	PersistDataManager.universeData.bastionData.DayComplete = true
	PersistDataManager.universeData.bastionData.UpdateCampsite(CurrentRoster)

	# then clean up the campaign
	currentMap.queue_free()
	queue_free()

func GetUnitFromTemplate(_unitTemplate : UnitTemplate):
	for u in CurrentRoster:
		if u.Template == _unitTemplate:
			return u

	return null

func OnRest():
	teamSizeLimit += 1

static func CreateNewCampaignInstance(_campaignTemplate : CampaignTemplate, _startingRoster : Array[UnitTemplate]):
	var campaignInstance = GameManager.GameSettings.CampaignInstancePrefab.instantiate() as Campaign
	if campaignInstance == null:
		return null

	GameManager.CurrentCampaign = campaignInstance
	campaignInstance.InitializeNewCampaign(_campaignTemplate, _startingRoster)
	return campaignInstance

func ToJSON():
	var jsonDict = {
		"currentCampaignTemplate" = currentCampaignTemplate.resource_path,
		"currentLevelDifficulty" = currentLevelDifficulty,
		"StartingRosterTemplates" = PersistDataManager.ResourcePathToJSON(StartingRosterTemplates),
		"campaignBlockMapIndex" = campaignBlockMapIndex,
		"traversedCampaignBlocks" = traversedCampaignBlocks,
		"startingCampaignBlock" = startingCampaignBlock.resource_path,
		"currentCampaignBlock" = currentCampaignBlock.resource_path,
		"currentMapOption" = currentMapOption.resource_path,
		"currentMapBlock" = currentMapBlock.resource_path,
		"campaignRNG" = CampaignRng.ToJSON(),
		"campaignLedger" = campaignLedger,
		"Convoy" = Convoy.ToJSON(),
		"teamSizeLimit" = teamSizeLimit
	}

	var children = UnitHoldingArea.get_children() as Array[UnitInstance]
	jsonDict["UnitsInHolding"] = PersistDataManager.ArrayToJSON(children)
	return jsonDict

static func FromJSON(_dict : Dictionary):
	var campaign = GameManager.GameSettings.CampaignInstancePrefab.instantiate() as Campaign


	PersistDataManager.JSONtoResourceFromPath(_dict["StartingRosterTemplates"], campaign.StartingRosterTemplates)

	campaign.currentCampaignTemplate = load(_dict["currentCampaignTemplate"])
	campaign.campaignBlockMapIndex = PersistDataManager.LoadFromJSON("campaignBlockMapIndex", _dict)
	campaign.traversedCampaignBlocks = PersistDataManager.LoadFromJSON("traversedCampaignBlocks", _dict)
	campaign.startingCampaignBlock = load(_dict["startingCampaignBlock"])
	campaign.currentCampaignBlock = load(_dict["currentCampaignBlock"])
	campaign.currentMapOption = load(_dict["currentMapOption"])
	campaign.currentLevelDifficulty = _dict["currentLevelDifficulty"]
	campaign.currentMapBlock = load(_dict["currentMapBlock"])
	campaign.teamSizeLimit = PersistDataManager.LoadFromJSON("teamSizeLimit", _dict)

	# TODO: Remove the campaign ledger if it has no functional use in the game
	#PersistDataManager.JSONtoResourceFromPath(_dict["campaignLedger"], campaign.campaignLedger)

	# Handle items in the convoy
	campaign.Convoy.FromJSON(_dict["Convoy"])


	# Handle the seeded rng
	if _dict.has("campaignRNG") && _dict["campaignRNG"] != null:
		campaign.CampaignRng = DeterministicRNG.FromJSON(_dict["campaignRNG"])


	if _dict.has("UnitsInHolding"):
		for u in _dict["UnitsInHolding"]:
			var dataAsJson = JSON.parse_string(u)
			var unit = UnitInstance.FromJSON(dataAsJson)
			if unit != null:
				campaign.UnitHoldingArea.add_child(unit)
				campaign.CurrentRoster.append(unit)

	campaign.TryLoadMap()

	return campaign

func TryLoadMap():
	# okay check if there is a map file
	if FileAccess.file_exists(PersistDataManager.MAP_FILE):
		var parsedString = PersistDataManager.GetJSONTextFromFile(PersistDataManager.MAP_FILE)
		if parsedString == null:
			return null

		var map = Map.FromJSON(parsedString, self)
		if map != null:
			currentMap = map
			resumingCampaign = true
			return map

	return null

func Save():
	var save_file = FileAccess.open(PersistDataManager.CAMPAIGN_FILE, FileAccess.WRITE)
	var toJSON = ToJSON()

	if currentMap != null:
		currentMap.Save()

	var stringify = JSON.stringify(toJSON, "\t")
	save_file.store_line(stringify)
