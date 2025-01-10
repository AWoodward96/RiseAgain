extends GameState
class_name BastionGameState


var bastion : Bastion

func Enter(_initData):
	var parentNode = GameManager.get_tree().get_first_node_in_group("BastionParent")
	bastion = GameManager.GameSettings.BastionPrefab.instantiate() as Bastion
	parentNode.add_child(bastion)
	# Bastion Initializes in Ready
	pass

func Exit():
	Bastion.CurrentBastion.ShutDown()
	pass
