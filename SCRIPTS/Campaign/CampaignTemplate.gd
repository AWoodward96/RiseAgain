extends Node2D
class_name CampaignTemplate

@export_category("Campaign Information")
@export var startingCampaignOptions : Array[CampaignBlock] # Just use duplicate entries if you want a 'weighted list'
@export var campaignBlockCap : int = -1
@export var campaignFinale : CampaignBlock

@export var AutoProceed : bool # When true, there is no campaign selection, we just go to the next node at index 0 depending on the ledger
@export var current_map_parent : Node2D

@export var UnitHoldingArea : Node2D
@export var MapRewardTable : LootTable # The loot table that the map will default to if not overwritten by the node itself

@export_category("Meta Data")
@export var loc_name : String
@export var loc_icon : Texture2D

var campaignLedger : Array[MapOption]
var currentMap : Map
var currentMapOption : MapOption
var startingCampaignBlock : CampaignBlock
var currentCampaignBlock : CampaignBlock
var currentMapBlock : MapBlock

var campaignBlockMapIndex : int
var traversedCampaignBlocks : int

var CampaignRng : RandomNumberGenerator
var CampaignSeed : int

var InitData : CampaignInitData
var StartingRosterTemplates : Array[UnitTemplate]
var CurrentRoster : Array[UnitInstance]

var ConvoyParent : Node2D
var Convoy : Array[Item]

var currentLevelDifficulty : int


func StartCampaign(_initData : CampaignInitData):
	InitData = _initData
	var cachedRng = RandomNumberGenerator.new()
	CampaignSeed = cachedRng.randi()
	CampaignRng = RandomNumberGenerator.new()
	CampaignRng.seed = CampaignSeed

	StartingRosterTemplates = InitData.InitialRoster
	CreateSquadInstance()

	if startingCampaignOptions.size() == 0:
		push_error("Campaign: " , name, " - does not have a starting campaign block and will not function.")
		return

	var startingCampaignBlockIndex = CampaignRng.randi_range(0, startingCampaignOptions.size() - 1)

	startingCampaignBlock = startingCampaignOptions[startingCampaignBlockIndex]
	currentCampaignBlock = startingCampaignBlock
	campaignBlockMapIndex = 0
	traversedCampaignBlocks = 0
	StartNextMap()

func StartNextMap():
	if campaignBlockMapIndex >= currentCampaignBlock.mapOptions.size():
		traversedCampaignBlocks += 1
		campaignBlockMapIndex = 0
		if campaignBlockCap != -1 && traversedCampaignBlocks >= campaignBlockCap && campaignFinale != null:
			# We in endgame
			currentCampaignBlock = campaignFinale
		else:
			if currentCampaignBlock.nextCampaignBlocks.size() == 0:
				# Well it's not.... easy to do anything here so just... end the map

				return
			# if we're traversed each map option in the current campaign block, we need to initialize the next campaign block
			var nextIndex = CampaignRng.randi_range(0, currentCampaignBlock.nextCampaignBlocks.size() - 1)
			#currentCampaignBlock = currentCampaignBlock.nextCampaignBlocks[nextIndex]
			currentCampaignBlock = load(currentCampaignBlock.nextCampaignBlocks[nextIndex]) as CampaignBlock


	GameManager.HideLoadingScreen()
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

	var MapRNG = CampaignRng.randi()
	currentMap.InitializeFromCampaign(self, CurrentRoster, MapRNG)
	current_map_parent.add_child(currentMap)
	campaignLedger.append(currentMapOption)

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

	return MapRewardTable

func OnRosterSelected(_roster : Array[UnitTemplate]):
	StartingRosterTemplates = _roster

func AddItemToConvoy(_item : Item):
	if ConvoyParent == null:
		# create a new one
		ConvoyParent = Node2D.new()
		ConvoyParent.name = "Convoy"
		add_child(ConvoyParent)
		ConvoyParent.visible = false # Should not be visible just in case there are visual effects on a prefab that might bleed through

	ConvoyParent.add_child(_item)
	Convoy.append(_item)

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
