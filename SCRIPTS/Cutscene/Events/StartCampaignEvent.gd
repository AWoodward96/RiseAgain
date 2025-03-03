extends CutsceneEventBase
class_name StartCampaignEvent

@export var campaign : CampaignTemplate
@export var roster : Array[UnitTemplate]

func Enter(_context : CutsceneContext):
	GameManager.StartCampaign(Campaign.CreateNewCampaignInstance(campaign, roster))
	return true
