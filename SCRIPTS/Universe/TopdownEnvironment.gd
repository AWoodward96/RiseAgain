extends Node2D
class_name TopdownEnvironment

@export var size : Vector2i
@export var offset : Vector2i
@export var tileSize : int = 64
@export var playerNode : Node2D
@export var interactableParent : Node2D
@export var IsSubEnvironment : bool
@export var SubEnvironments : Array[TopdownEnvironment]

var player : TopDownPlayer
var allInteractables : Array[TopdownInteractable]

func _ready() -> void:
	if !IsSubEnvironment:
		if playerNode != null:
			# create the player
			player = GameManager.GameSettings.TopdownPlayerControllerPrefab.instantiate() as TopDownPlayer
			if player != null:
				player.Initialize(self)
				add_child(player)
				player.position = playerNode.global_position

	InitializeInteractables()

func InitializeInteractables():
	allInteractables.clear()
	if interactableParent == null:
		return

	var children = interactableParent.get_children()
	for c in children:
		var asInteractable = c as TopdownInteractable
		if asInteractable != null:
			allInteractables.append(asInteractable)

	pass

func Shutdown():
	for i in allInteractables:
		i.OnShutdown()

	for env in SubEnvironments:
		env.Shutdown()

	# clear the player
	if player != null:
		player.queue_free()
	pass
