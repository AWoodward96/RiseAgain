extends CutsceneEventBase
class_name StartCampaignEvent

#@export var campaign : CampaignTemplate
@export var poiID : String
@export var roster : Array[UnitTemplate]

func Enter(_context : CutsceneContext):
	var poi = WorldMap.GetPOIFromID(poiID)
	if poi == null:
		push_error("Could not find POI of ID: [", poiID, "] on the world map. Did you type it correctly?")
		return true

	GameManager.StartCampaign(Campaign.CreateNewCampaignInstance(poi, roster))
	return true
