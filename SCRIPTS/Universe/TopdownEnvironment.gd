extends Node2D
class_name TopdownEnvironment

@export var size : Vector2i
@export var tileSize : int = 64
@export var playerNode : Node2D
@export var interactableParent : Node2D

var player : TopDownPlayer
var allInteractables : Array[TopdownInteractable]

func _ready() -> void:
	if playerNode != null:
		# create the player
		player = GameManager.GameSettings.TopdownPlayerControllerPrefab.instantiate() as TopDownPlayer
		if player != null:
			player.Initialize(self)
			playerNode.add_child(player)
			player.position = Vector2.ZERO

	InitializeInteractables()

func InitializeInteractables():
	allInteractables.clear()
	var children = interactableParent.get_children()
	for c in children:
		var asInteractable = c as TopdownInteractable
		if asInteractable != null:
			allInteractables.append(asInteractable)

	pass

func Shutdown():
	for i in allInteractables:
		i.OnShutdown()

	# clear the player
	player.queue_free()
	pass
