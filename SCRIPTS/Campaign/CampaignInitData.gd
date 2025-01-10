class_name CampaignInitData

var InitialRoster : Array[UnitTemplate]
var Campaign : CampaignTemplate

static func Construct(_campaign : CampaignTemplate, _roster : Array[UnitTemplate]):
	var initData = CampaignInitData.new()
	initData.Campaign = _campaign
	initData.InitialRoster = _roster
	return initData

func StartCampaign():
	if Campaign != null:
		Campaign.StartCampaign(self)
