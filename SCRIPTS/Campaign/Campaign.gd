extends Node2D
class_name Campaign

@export var currentCampaignTemplate : CampaignTemplate
@export var current_map_parent : Node2D
@export var UnitHoldingArea : Node2D

var campaignLedger : Array[MapOption]
var currentMap : Map
var currentMapOption : MapOption
var currentMapBlock : MapBlock
var startingCampaignBlock : CampaignBlock
var currentCampaignBlock : CampaignBlock

var campaignBlockMapIndex : int
var traversedCampaignBlocks : int

var CampaignRng : DeterministicRNG

var StartingRosterTemplates : Array[UnitTemplate]
var CurrentRoster : Array[UnitInstance]

var ConvoyParent : Node2D
var Convoy : Array[Item]

var resumingCampaign : bool = false
var currentLevelDifficulty : int

func InitializeNewCampaign(_template : CampaignTemplate, _startingRoster : Array[UnitTemplate]):
	StartingRosterTemplates = _startingRoster
	currentCampaignTemplate = _template
	campaignBlockMapIndex = 0
	traversedCampaignBlocks = 0

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
	CreateSquadInstance()

	if currentMap != null:
		if !resumingCampaign:
			StartMap()
		else:
			ResumeMap()

func StartNextMap():
	GetNextMapOption()
	StartMap()

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
		push_error("Campaign: " , name, " - Could not descern what the next map should be from index: ", campaignBlockMapIndex)
		return

	currentMap = currentMapOption.GetMap().instantiate() as Map

# Takes the current map option and starts it
func StartMap():
	if currentMap == null:
		return

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

	current_map_parent.add_child(currentMap)
	campaignLedger.append(currentMapOption)
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
		AddUnitToRoster(unit)

func MapComplete():
	# Persist the current roster between maps
	RemoveEmptyRosterEntries()
	for unit in CurrentRoster:
		unit.OnMapComplete()
		var parent = unit.get_parent()
		if parent != null:
			parent.remove_child(unit)

		UnitHoldingArea.add_child(unit)

	campaignBlockMapIndex += 1
	StartNextMap()

func RemoveEmptyRosterEntries():
	var i = CurrentRoster.size() - 1
	while i >= 0:
		if not is_instance_valid(CurrentRoster[i]):
			CurrentRoster.remove_at(i)
		i -= 1

func GetMapRewardTable():
	if currentMapOption != null && currentMapOption.rewardOverride != null:
		return currentMapOption.rewardOverride

	return currentCampaignTemplate.MapRewardTable

func OnRosterSelected(_roster : Array[UnitTemplate]):
	StartingRosterTemplates = _roster

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
		"campaignRNG" = CampaignRng.ToJSON(),
		"currentMapOption" = currentMapOption.resource_path,
		"campaignLedger" = PersistDataManager.ResourcePathToJSON(campaignLedger),
		"currentMapBlock" = currentMapBlock.resource_path,
		"Convoy" = PersistDataManager.ArrayToJSON(Convoy)
	}
	return jsonDict

static func FromJSON(_dict : Dictionary):
	var campaign = GameManager.GameSettings.CampaignInstancePrefab.instantiate() as Campaign
	campaign.currentCampaignTemplate = load(_dict["currentCampaignTemplate"])
	campaign.campaignBlockMapIndex = PersistDataManager.LoadFromJSON("campaignBlockMapIndex", _dict)
	campaign.traversedCampaignBlocks = PersistDataManager.LoadFromJSON("traversedCampaignBlocks", _dict)
	campaign.startingCampaignBlock = load(_dict["startingCampaignBlock"])
	campaign.currentCampaignBlock = load(_dict["currentCampaignBlock"])
	campaign.currentMapOption = load(_dict["currentMapOption"])
	campaign.currentLevelDifficulty = _dict["currentLevelDifficulty"]
	campaign.currentMapBlock = load(_dict["currentMapBlock"])

	PersistDataManager.JSONtoResourceFromPath(_dict["StartingRosterTemplates"], campaign.StartingRosterTemplates)
	PersistDataManager.JSONtoResourceFromPath(_dict["campaignLedger"], campaign.campaignLedger)

	campaign.CreateConvoyParent()
	var data = PersistDataManager.JSONToArray(_dict["Convoy"], Callable.create(Item, "FromJSON"))
	campaign.Convoy.assign(data)
	for item in campaign.Convoy:
		campaign.ConvoyParent.add_child(item)

	if _dict.has("campaignRNG") && _dict["campaignRNG"] != null:
		campaign.CampaignRng = DeterministicRNG.FromJSON(_dict["campaignRNG"])

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

	return null

func Save():
	var save_file = FileAccess.open(PersistDataManager.CAMPAIGN_FILE, FileAccess.WRITE)
	var toJSON = ToJSON()

	if currentMap != null:
		currentMap.Save()

	var stringify = JSON.stringify(toJSON, "\t")
	save_file.store_line(stringify)
