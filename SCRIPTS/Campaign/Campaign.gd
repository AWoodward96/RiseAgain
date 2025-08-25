extends Node2D
class_name Campaign

@export var current_map_parent : Node2D
@export var UnitHoldingArea : Node2D

var startingPOI : POI
var campaignLedger : Array[String] # This uses the internal ID name to determine which node is which
var currentPOI : POI

var currentMap : Map
var currentMapOption : MapOption
#var currentMapBlock : MapBlock
#var startingCampaignBlock : CampaignBlock
#var currentCampaignBlock : CampaignBlock

#var campaignBlockMapIndex : int
var traversedPOIs : int

var CampaignRng : DeterministicRNG

var StartingRosterTemplates : Array[UnitTemplate]
var CurrentRoster : Array[UnitInstance]
var DeadUnits : Array[UnitTemplate]

var ConvoyParent : Node2D
var Convoy : Array[Item]

var resumingCampaign : bool = false
var currentLevelDifficulty : int
var alphaTeamSelection
var debug_leveloverride : int = 0

func InitializeNewCampaign(_startingPOI : POI, _startingRoster : Array[UnitTemplate]):
	StartingRosterTemplates = _startingRoster
	traversedPOIs = 0

	CampaignRng = DeterministicRNG.Construct()
	startingPOI = _startingPOI
	currentPOI = _startingPOI

	GetNextMapOption()

func StartCampaign():
	UnitHoldingArea.visible = false

	if currentMap != null:
		if !resumingCampaign:
			CreateSquadInstance()
			StartMap()
		else:
			ResumeMap()

func GetNextMapOption():
	# open up the map, if it's not already open
	if WorldMap.fullscreenHelperUI == null:
		WorldMap.OpenWorldMapFullscreenUI(WorldMap.WorldMapUIState.NextMap)

	print("Asking for the next map option")
	WorldMap.POISelected.connect(OnPOISelected)
	#WorldMap.RefreshCampaign()

	# wait for world map selection?

	#if campaignBlockMapIndex >= currentCampaignBlock.mapOptions.size():
		#traversedCampaignBlocks += 1
		#campaignBlockMapIndex = 0
		#if currentCampaignTemplate.campaignBlockCap != -1 && traversedCampaignBlocks >= currentCampaignTemplate.campaignBlockCap && currentCampaignTemplate.campaignFinale != null:
			## We in endgame
			#currentCampaignBlock = currentCampaignTemplate.campaignFinale
		#else:
			#if currentCampaignBlock.nextCampaignBlocks.size() == 0:
				## Well it's not.... easy to do anything here so just... end the map
				#ReportCampaignResult(true)
				#GameManager.ChangeGameState(BastionGameState.new(), null)
				#return
#
			## if we're traversed each map option in the current campaign block, we need to initialize the next campaign block
			#var nextIndex = CampaignRng.NextInt(0, currentCampaignBlock.nextCampaignBlocks.size() - 1)
			#currentCampaignBlock = load(currentCampaignBlock.nextCampaignBlocks[nextIndex]) as CampaignBlock
#
	#currentMapBlock = currentCampaignBlock.GetMapBlock(campaignBlockMapIndex)
	#if currentMapBlock == null:
		#push_error("Campaign: " , name, " - rolled a map block from the map options that is null somehow.")
		#return
#
	#currentMapOption = currentMapBlock.GetMapFromBlock()
	#if currentMap != null:
		#currentMap.queue_free()
#
	#var newMap = currentMapOption.GetMap()
	#if newMap == null:
		#push_error("Campaign: " , name, " - Could not descern what the next map should be from index: ", campaignBlockMapIndex)
		#return
#
	#currentMap = newMap.instantiate() as Map
	pass

func OnPOISelected(_poi : POI):
	WorldMap.POISelected.disconnect(OnPOISelected)

	# okay so we have the poi now we need to evaluate what the next map is
	var mapOption = _poi.Maps.GetMapFromBlock()
	if currentMap != null:
		currentMap.queue_free()

	currentMapOption = mapOption
	var newMap = mapOption.GetMap()
	if newMap == null:
		GetNextMapOption()
		return

	currentMap = newMap.instantiate() as Map
	currentPOI = _poi
	WorldMap.CloseUI()
	StartMap()
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
	if CurrentRoster.size() == 0:
		var ui = UIManager.AlphaUnitSelection.instantiate()
		ui.Initialize(currentMap.startingPositions.size())
		ui.OnRosterSelected.connect(OnRosterSelected)
		add_child(ui)

		#waits until that UI is closed, when the squad is all selected
		await ui.OnRosterSelected
		CreateSquadInstance()

	var MapRNGSeed = CampaignRng.NextInt(0, 10000000)
	currentMap.InitializeFromCampaign(self, CurrentRoster, MapRNGSeed)

	if currentMap.get_parent() != current_map_parent:
		current_map_parent.add_child(currentMap)
#
	#campaignLedger.append(currentMapOption)
	campaignLedger.append(currentPOI.internal_name)
	GameManager.HideLoadingScreen()
	PersistDataManager.SaveCampaign()

func ResumeMap():
	if currentMap == null:
		return

	# We may need to not do this, Ionno
	currentMap.PreInitialize()

	currentMap.ResumeFromCampaign(self)
	current_map_parent.add_child(currentMap)
	GameManager.HideLoadingScreen()

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

	GetNextMapOption()
	GameManager.HideLoadingScreen()

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
	if currentMapOption != null && currentMapOption.rewardOverride != null:
		return currentMapOption.rewardOverride

	return GameManager.GameSettings.DefaultMapRewardTable

func OnRosterSelected(_roster : Array[UnitTemplate], _levelOverride : int):
	StartingRosterTemplates = _roster
	debug_leveloverride = _levelOverride


func AddItemToConvoy(_item : Item):
	CreateConvoyParent()
	ConvoyParent.add_child(_item)
	Convoy.append(_item)

func CreateConvoyParent():
	if ConvoyParent == null:
		# create a new one
		ConvoyParent = Node2D.new()
		ConvoyParent.name = "Convoy"
		add_child(ConvoyParent)
		ConvoyParent.visible = false # Should not be visible just in case there are visual effects on a prefab that might bleed through


func RemoveItemFromConvoy(_item : Item, _unitToGiveTo : UnitInstance, _slotIndex : int):
	var index = Convoy.find(_item)
	if index == -1:
		return

	if _unitToGiveTo == null || _slotIndex < 0 || _slotIndex >= GameManager.GameSettings.ItemSlotsPerUnit:
		return

	var item = Convoy[index]
	Convoy.remove_at(index)
	ConvoyParent.remove_child(item)
	_unitToGiveTo.EquipItem(_slotIndex, item)


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
	# TODO: Figure out where you're reporting your results too

	# Tell the Bastion Persist Data that they need to generate a new set of tavern dwellers
	GameManager.CurrentCampaign = null
	PersistDataManager.ClearCampaign()
	PersistDataManager.universeData.bastionData.DayComplete = true
	PersistDataManager.universeData.bastionData.UpdateCampsite(CurrentRoster)

	# then clean up the campaign
	currentMap.queue_free()
	queue_free()

static func CreateNewCampaignInstance(_startingPOI : POI, _startingRoster : Array[UnitTemplate]):
	var campaignInstance = GameManager.GameSettings.CampaignInstancePrefab.instantiate() as Campaign
	if campaignInstance == null:
		return null

	GameManager.CurrentCampaign = campaignInstance
	campaignInstance.InitializeNewCampaign(_startingPOI, _startingRoster)
	return campaignInstance

func ToJSON():
	var jsonDict = {
		#"currentCampaignTemplate" = currentCampaignTemplate.resource_path,
		"currentLevelDifficulty" = currentLevelDifficulty,
		"StartingRosterTemplates" = PersistDataManager.ResourcePathToJSON(StartingRosterTemplates),
		#"campaignBlockMapIndex" = campaignBlockMapIndex,
		#"traversedCampaignBlocks" = traversedCampaignBlocks,
		#"startingCampaignBlock" = startingCampaignBlock.resource_path,
		#"currentCampaignBlock" = currentCampaignBlock.resource_path,
		"currentPOI" = currentPOI.internal_name,
		"startingPOI" = startingPOI.internal_name,
		"campaignRNG" = CampaignRng.ToJSON(),
		"currentMapOption" = currentMapOption.resource_path,
		"campaignLedger" = campaignLedger,
		#"currentMapBlock" = currentMapBlock.resource_path,
		"Convoy" = PersistDataManager.ArrayToJSON(Convoy)
	}

	var children = UnitHoldingArea.get_children() as Array[UnitInstance]
	jsonDict["UnitsInHolding"] = PersistDataManager.ArrayToJSON(children)
	return jsonDict

static func FromJSON(_dict : Dictionary):
	var campaign = GameManager.GameSettings.CampaignInstancePrefab.instantiate() as Campaign
	#campaign.currentCampaignTemplate = load(_dict["currentCampaignTemplate"])
	#campaign.campaignBlockMapIndex = PersistDataManager.LoadFromJSON("campaignBlockMapIndex", _dict)
	#campaign.traversedCampaignBlocks = PersistDataManager.LoadFromJSON("traversedCampaignBlocks", _dict)
	#campaign.startingCampaignBlock = load(_dict["startingCampaignBlock"])
	#campaign.currentCampaignBlock = load(_dict["currentCampaignBlock"])
	campaign.currentMapOption = load(_dict["currentMapOption"])
	campaign.currentLevelDifficulty = _dict["currentLevelDifficulty"]
	#campaign.currentMapBlock = load(_dict["currentMapBlock"])

	PersistDataManager.JSONtoResourceFromPath(_dict["StartingRosterTemplates"], campaign.StartingRosterTemplates)


	campaign.currentPOI = WorldMap.GetPOIFromID(_dict["currentPOI"])
	campaign.startingPOI = WorldMap.GetPOIFromID(_dict["startingPOI"])

	# Gotta load the ledger manually
	campaign.campaignLedger.clear()
	for string in _dict["campaignLedger"]:
		campaign.campaignLedger.append(string)

	campaign.CreateConvoyParent()


	for element in _dict["Convoy"]:
		if element == "NULL":
			continue

		var elementAsDict = JSON.parse_string(element)
		if elementAsDict == null:
			continue

		var prefab = load(elementAsDict["prefab"]) as PackedScene
		if prefab == null:
			continue

		var newInstance = prefab.instantiate() as Item
		newInstance.FromJSON(elementAsDict)
		campaign.ConvoyParent.add_child(newInstance)
		campaign.Convoy.append(newInstance)

	#var data = PersistDataManager.JSONToArray(_dict["Convoy"], Callable.create(Item, "FromJSON"))
	#campaign.Convoy.assign(data)
	#for item : Item in campaign.Convoy:
		#if item == null:
			#continue
#
		#item.reparent(campaign.ConvoyParent)
		#campaign.ConvoyParent.add_child(item)

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
