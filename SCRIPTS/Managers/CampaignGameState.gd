extends GameState
class_name CampaignGameState

var campaign : Campaign

func Enter(_data):
	if _data is not Campaign:
		push_error("Entering CampaignGameState without a Campaign that's preinitialized is not allowed. Please fix")
		return

	campaign = _data as Campaign

	GameManager.CurrentCampaign = campaign
	var campaignParent = GameManager.get_tree().get_first_node_in_group("CampaignParent")
	campaignParent.add_child(campaign)
	campaign.StartCampaign()
	pass

func Exit():
	# clean up the maps
	pass
