extends MapStateBase
class_name VictoryState

var combatHUD : CombatHUD
var rewardUI : RewardsUI

func Enter(_map : Map, _ctrl : PlayerController):
	super(_map, _ctrl)

	controller.EnterEndGameState()

	if _map.mapType == _map.MAPTYPE.Standard:
		combatHUD = controller.combatHUD
		if combatHUD != null:
			AudioManager.PlayVictoryStinger()
			if _map.Biome != null && _map.Biome.VictoryDelay > 0:
				await GameManager.get_tree().create_timer(_map.Biome.VictoryDelay).timeout

			combatHUD.PlayVictoryBanner()
			await combatHUD.BannerAnimComplete

		if map.CurrentCampaign != null:
			if !CutsceneManager.BlockRewardSelection:
				var resultsUI = UIManager.OpenFullscreenUI(UIManager.MapResultsUI) as MapResultUI
				resultsUI.Initialize(_map)
				await resultsUI.ResultsComplete


	var signalCallback = UIManager.ShowLoadingScreen()
	await signalCallback.ScreenObscured

	if controller != null && controller.combatHUD != null:
		controller.combatHUD.queue_free()

	if map.CurrentCampaign != null:
		map.CurrentCampaign.MapComplete()

	pass


func Exit():
	pass

func Update(_delta):
	pass

func ToString():
	return "VictoryState"

func ToJSON():
	return "VictoryState"
