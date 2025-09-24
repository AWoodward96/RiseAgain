extends CutsceneEventBase
class_name StartCampaignEvent

@export var campaign : CampaignTemplate
#@export var poiID : String
@export var roster : Array[UnitTemplate]

func Enter(_context : CutsceneContext):
	if campaign == null:
		push_error("Could not start a null campaign.")
		return true

	GameManager.StartCampaign(Campaign.CreateNewCampaignInstance(campaign, roster))
	GameManager.CurrentCampaign.CreateSquadInstance()
	#GameManager.CurrentCampaign.OnPOISelected(WorldMap.GetPOIFromID(poiID))
	return true
