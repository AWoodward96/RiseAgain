extends Node2D
class_name CampaignTemplate

@export var ledger_root  : Node2D
@export var AutoProceed : bool # When true, there is no campaign selection, we just go to the next node at index 0 depending on the ledger
@export var current_map_parent : Node2D
@export var UnitHoldingArea : Node2D

var PersistData : CampaignPersistData

var campaignLedger : Array[int]
var currentNode : CampaignNode
var currentMap : Map

var CampaignRng : RandomNumberGenerator
var CampaignSeed : int

var CurrentRoster : Array[UnitInstance]
var RosterTemplates : Array[UnitTemplate]

var CurrentMap

func StartCampaign(_roster : Array[UnitTemplate]):
	var cachedRng = RandomNumberGenerator.new()
	CampaignSeed = cachedRng.randi()
	CampaignRng = RandomNumberGenerator.new()
	CampaignRng.seed = CampaignSeed

	RosterTemplates = _roster
	if PersistData == null:
		PersistData = CampaignPersistData.new()

	#PersistData.Construct(CurrentRoster)


	campaignLedger.clear()
	currentNode = ledger_root.get_child(0)
	if currentNode != null && AutoProceed:
		StartMap(currentNode, 0)


func StartMap(_campaignNode : CampaignNode, _index : int):
	var map = _campaignNode.MapPrefab.instantiate() as Map
	if map == null:
		return

	GameManager.HideLoadingScreen()
	currentMap = map
	var MapRNG = CampaignRng.randi()

	currentMap.PreInitialize()
	if CurrentRoster.size() == 0:
		var ui = GameManager.AlphaUnitSelection.instantiate()
		ui.Initialize(currentMap.startingPositions.size())
		ui.OnRosterSelected.connect(OnRosterSelected)
		add_child(ui)

		#waits until that UI is closed, when the squad is all selected
		await ui.OnRosterSelected
		CreateSquadInstance()

	PersistData.Construct(CurrentRoster)
	currentMap.InitializeFromCampaign(self, CurrentRoster, MapRNG)
	current_map_parent.add_child(map)
	campaignLedger.append(_index)

func CreateSquadInstance():
	for unit in RosterTemplates:
		var unitInstance = GameManager.UnitSettings.UnitInstancePrefab.instantiate() as UnitInstance
		unitInstance.Initialize(unit)
		CurrentRoster.append(unitInstance)
		UnitHoldingArea.add_child(unitInstance)

func MapComplete():
	var walkedNode = ledger_root
	for i in campaignLedger:
		walkedNode = walkedNode.get_child(i)

	RemoveEmptyRosterEntries()
	for unit in CurrentRoster:
		var parent = unit.get_parent()
		if parent != null:
			parent.remove_child(unit)

		UnitHoldingArea.add_child(unit)

	# TODO: Figure out how to carry over units from one map to another
	var nextMap
	if AutoProceed:
		nextMap = walkedNode.get_child(0)
		if nextMap != null:
			currentMap.queue_free()
			StartMap(nextMap, 0)

func RemoveEmptyRosterEntries():
	var i = CurrentRoster.size() - 1
	while i >= 0:
		if not is_instance_valid(CurrentRoster[i]):
			CurrentRoster.remove_at(i)
		i -= 1


func OnRosterSelected(_roster : Array[UnitTemplate]):
	RosterTemplates = _roster
