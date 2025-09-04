extends TopdownInteractable
class_name FullscreenToipdownInteractable

# opens a UI when interacted with
@export var Fullscreen : PackedScene

var hasInteractable
var UI : FullscreenUI

func OnInteract():
	super()
	TopDownPlayer.BlockInputCounter += 1
	SetInteractable(true)
	pass

func SetInteractable(_bool : bool):
	hasInteractable = true
	if _bool:
		OpenFullscreenUI()
	else:
		if UI != null:
			UI.queue_free()

func OpenFullscreenUI():
	UI = UIManager.OpenFullscreenUI(Fullscreen)
	pass

func _process(_delta: float) -> void:
	if InputManager.cancelDown && hasInteractable:
		TopDownPlayer.BlockInputCounter -= 1
		SetInteractable(false)
