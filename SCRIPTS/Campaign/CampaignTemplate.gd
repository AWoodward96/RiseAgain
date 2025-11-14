extends Resource
class_name CampaignTemplate

@export_category("Campaign Information")
@export var startingCampaignOptions : Array[CampaignBlock] # Just use duplicate entries if you want a 'weighted list'
@export var campaignBlockCap : int = -1

@export var requiredUnit : Array[UnitTemplate]
@export var startingRosterSize : int = 2

@export var MapRewardTable : LootTable # The loot table that the map will default to if not overwritten by the node itself

@export_category("Meta Data")
@export var loc_name : String
@export var loc_desc : String
@export var loc_icon : Texture2D


func GetInitialCampaignBlock(_rng : DeterministicRNG):
	if startingCampaignOptions.size() == 0:
		push_error("Campaign: " , self.resource_name, " - does not have a starting campaign block and will not function.")
		return

	var startingCampaignBlockIndex = _rng.NextInt(0, startingCampaignOptions.size() - 1)

	return startingCampaignOptions[startingCampaignBlockIndex]
