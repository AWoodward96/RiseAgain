extends TopdownInteractable
class_name FullscreenToipdownInteractable

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
	#else:
		#if UI != null:
			#UI.queue_free()

func OpenFullscreenUI():
	if UI == null:
		UI = UIManager.OpenFullscreenUI(Fullscreen)
	pass

#func _process(_delta: float) -> void:
	#if InputManager.cancelDown && hasInteractable:
		#TopDownPlayer.BlockInputCounter -= 1
		#SetInteractable(false)

func OnUIClosed(_ui : FullscreenUI):
	if _ui != null && _ui == UI:
		TopDownPlayer.BlockInputCounter -= 1
		SetInteractable(false)
