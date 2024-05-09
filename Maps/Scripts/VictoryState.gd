extends MapStateBase
class_name VictoryState

var combatHUD : CombatHUD

func Enter(_map : Map, _ctrl : PlayerController):
	super(_map, _ctrl)

	controller.BlockMovementInput = true
	controller.reticle.visible = false

	combatHUD = controller.combatHUD
	if combatHUD != null:
		combatHUD.PlayVictoryBanner()
		await combatHUD.BannerAnimComplete

	# TODO : Item selection, or Unit Selection

	await map.get_tree().create_timer(1).timeout

	var signalCallback = GameManager.ShowLoadingScreen()
	await signalCallback

	if map.CurrentCampaign != null:
		map.CurrentCampaign.MapComplete()

	pass

func Exit():
	pass

func Update(_delta):
	pass

func OnTileSelected(_tile : Tile):
	pass
