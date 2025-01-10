extends GameState
class_name CampaignGameState

var initData : CampaignInitData

func Enter(_data):
	if _data is not CampaignInitData:
		push_error("Entering CampaignGameState without CampaignInitData is not allowed. Please fix")
		return

	initData = _data as CampaignInitData

	GameManager.CurrentCampaign = initData.Campaign
	var campaignParent = GameManager.get_tree().get_first_node_in_group("CampaignParent")
	campaignParent.add_child(initData.Campaign)
	initData.StartCampaign()
	pass
