extends CutsceneEventBase
class_name SaveCampaignEvent

func Enter(_cutscene : CutsceneContext):
	PersistDataManager.SaveCampaign()
	return true
