extends GameState
class_name BastionGameState

var bastion : Bastion

func Enter(_initData):
	if LoadingScreen.Obscured:
		UIManager.HideLoadingScreen()
	else:
		var signalCallback = UIManager.ShowLoadingScreen()
		await signalCallback.ScreenObscured
		# This is a bit of a safety call here but close the worldmap if it's up
		WorldMap.CloseUI()
		UIManager.HideLoadingScreen()



	TopDownPlayer.BlockInputCounter = 0
	var parentNode = GameManager.get_tree().get_first_node_in_group("BastionParent")
	bastion = GameManager.GameSettings.BastionPrefab.instantiate() as Bastion
	parentNode.add_child(bastion)
	# Bastion Initializes in Ready
	pass



func Exit():
	Bastion.CurrentBastion.ShutDown()
	pass
