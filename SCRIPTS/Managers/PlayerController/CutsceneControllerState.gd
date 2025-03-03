extends PlayerControllerState
class_name CutsceneControllerState


func _Enter(_ctrl : PlayerController, data):
	super(_ctrl, data)
	ctrl.BlockMovementInput = true
	ctrl.CreateCombatHUD()
	reticle.visible = false
