extends MapStateBase
class_name LossState

var combatHUD : CombatHUD

# Chat is this Loss?

func Enter(_map : Map, _ctrl : PlayerController):
	super(_map, _ctrl)

	controller.EnterEndGameState()

	combatHUD = controller.combatHUD
	if combatHUD != null:
		AudioManager.PlayLossStinger()
		combatHUD.PlayLossBanner()
		await combatHUD.BannerAnimComplete

	var signalCallback = GameManager.ShowLoadingScreen()
	await signalCallback.ScreenObscured

	if map.CurrentCampaign != null:
		map.CurrentCampaign.ReportCampaignResult(false)
	else:
		map.queue_free()

	if !Main.Root.DEBUG_ShowcaseMode:
		AudioManager.ClearTracks()
		GameManager.ChangeGameState(BastionGameState.new(), null)
	pass


func ToJSON():
	return "LossState"
