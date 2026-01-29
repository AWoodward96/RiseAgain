class_name CampaignInitData

var InitialRoster : Array[UnitTemplate]
var CurrentCampaign : CampaignTemplate

static func Construct(_campaign : CampaignTemplate, _roster : Array[UnitTemplate]):
	var initData = CampaignInitData.new()
	initData.CurrentCampaign = _campaign
	initData.InitialRoster = _roster
	return initData

func StartCampaign():
	if CurrentCampaign != null:
		CurrentCampaign.StartCampaign(self)
