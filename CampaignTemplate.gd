extends Node2D
class_name CampaignTemplate

const RNGMAX = 1000000
@export var Origin : CampaignNode
@export var AutoProceed : bool # When true, there is no campaign selection, we just go to the next node at index 0 depending on the ledger

@onready var current_map_parent = %CurrentMap
@onready var ledger_root = $LedgerRoot

var campaignLedger : Array[int]
var currentNode : CampaignNode

var CampaignRng : RandomNumberGenerator
var CampaignSeed : int

func StartCampaign():
	var cachedRng = RandomNumberGenerator.new()
	CampaignSeed = cachedRng.randi_range(0, RNGMAX)
	CampaignRng.new()
	CampaignRng.seed = CampaignSeed
	
	campaignLedger.clear()
	currentNode = ledger_root.get_child(0)
	if currentNode != null && AutoProceed:
		StartMap(currentNode, 0)


func StartMap(_campaignNode : CampaignNode, _index : int):
	var map = _campaignNode.MapPrefab.instantiate() as Map
	if map == null:
		return
	
	var MapRNG = CampaignRng.randi(0, RNGMAX)
	map.InitializeFromCampaign(MapRNG)
	current_map_parent.add_child(map)
	campaignLedger.append(_index)
