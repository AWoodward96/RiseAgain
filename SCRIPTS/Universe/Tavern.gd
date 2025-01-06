extends TopdownInteractable
class_name Tavern


@export var UIParent : Node

var hasInteractable : bool

func _ready() -> void:
	super()
	UIParent.visible = false

	# When placed into the scene, the tavern should check persistence to see if it has a in-tavern roster yet, and if not, generate a new one



# This is where the Player goes and sets off on a mission
func OnInteract():
	super()
	TopDownPlayer.BlockInputCounter += 1
	SetInteractable(true)
	pass

func SetInteractable(_bool : bool):
	UIParent.visible = _bool
	hasInteractable = true

func _process(_delta: float) -> void:
	if InputManager.cancelDown && hasInteractable:
		TopDownPlayer.BlockInputCounter -= 1
		SetInteractable(false)
