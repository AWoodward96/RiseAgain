extends Node2D
class_name CampaignTemplate

@export var ledger_root  : Node2D
@export var AutoProceed : bool # When true, there is no campaign selection, we just go to the next node at index 0 depending on the ledger
@export var current_map_parent : Node2D

var campaignLedger : Array[int]
var currentNode : CampaignNode
var currentMap : Map

var CampaignRng : RandomNumberGenerator
var CampaignSeed : int

var CurrentRoster : Array[UnitTemplate]

var CurrentMap

func StartCampaign(_roster : Array[UnitTemplate]):
	var cachedRng = RandomNumberGenerator.new()
	CampaignSeed = cachedRng.randi()
	CampaignRng = RandomNumberGenerator.new()
	CampaignRng.seed = CampaignSeed

	CurrentRoster = _roster

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

	currentMap.InitializeFromCampaign(self, CurrentRoster, MapRNG)
	current_map_parent.add_child(map)
	campaignLedger.append(_index)

func MapComplete():
	var walkedNode = ledger_root
	for i in campaignLedger:
		walkedNode = walkedNode.get_child(i)

	# TODO: Figure out how to carry over units from one map to another
	var nextMap
	if AutoProceed:
		nextMap = walkedNode.get_child(0)
		if nextMap != null:
			currentMap.queue_free()
			StartMap(nextMap, 0)

func OnRosterSelected(_roster : Array[UnitTemplate]):
	CurrentRoster = _roster
