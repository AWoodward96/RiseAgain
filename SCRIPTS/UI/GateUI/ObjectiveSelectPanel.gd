extends FocusEntryPanel
class_name ObjectiveSelectPanel

signal CampaignSelected(_campaignTemplate : CampaignTemplate)

func Refresh():
	var availableCampaigns = GetAvailableCampaigns()
	entryParent.ClearEntries()
	for c in availableCampaigns:
		var entry = entryParent.CreateEntry(entryPrefab)
		entry.Initialize(c)
		entry.CampaignSelected.connect(OnCampaignSelected)

	entryParent.FocusFirst()
	pass


func OnCampaignSelected(_campaignTemplate : CampaignTemplate):
	CampaignSelected.emit(_campaignTemplate)

func GetAvailableCampaigns():
	# TODO: Set up a persisted campaign data system

	# For now, it's all just in the game settings
	return GameManager.GameSettings.CampaignManifest
