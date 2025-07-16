extends CutsceneEventBase
class_name ReturnToBastionEvent

## If there is a current campaign, we need to clean it up. This variable determines if it's considered a victory or not
@export var IsCampaignConsideredVictorious : bool = true

func Enter(_context : CutsceneContext):
	if GameManager.CurrentCampaign != null:
		GameManager.CurrentCampaign.ReportCampaignResult(IsCampaignConsideredVictorious)

	GameManager.ReturnToBastion()
	return true
