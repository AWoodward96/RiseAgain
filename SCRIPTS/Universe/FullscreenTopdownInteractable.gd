extends TopdownInteractable
class_name FullscreenTopdownInteractable

# opens a UI when interacted with
@export var Fullscreen : PackedScene

var hasInteractable
var UI : FullscreenUI

func _ready():
	super()
	UIManager.UIClosed.connect(OnUIClosed)

func OnInteract():
	super()
	TopDownPlayer.BlockInputCounter += 1
	SetInteractable(true)
	pass

func SetInteractable(_bool : bool):
	hasInteractable = true
	if _bool:
		OpenFullscreenUI()

func OpenFullscreenUI():
	if UI == null:
		UI = UIManager.OpenFullscreenUI(Fullscreen)
	pass


func OnUIClosed(_ui : FullscreenUI):
	if _ui != null && _ui == UI:
		TopDownPlayer.BlockInputCounter -= 1
		SetInteractable(false)
