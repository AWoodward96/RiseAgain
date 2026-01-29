extends Node2D
class_name TopdownInteractable

@export var interactableArea : Area2D
@export var visual : Sprite2D


func _ready() -> void:
	interactableArea.body_entered.connect(OnBodyEnter)
	interactableArea.body_exited.connect(OnBodyExit)

	if visual != null:
		visual.material.set_shader_parameter("enabled", false)

func OnBodyEnter(_body: Node2D) -> void:
	if !_body.is_in_group("Player"):
		return

	if TopDownPlayer.CurrentInteractable == null:
		TopDownPlayer.CurrentInteractable = self
		if visual != null:
			visual.material.set_shader_parameter("enabled", true)


func OnBodyExit(_body: Node2D) -> void:
	if !_body.is_in_group("Player"):
		return

	if TopDownPlayer.CurrentInteractable == self:
		TopDownPlayer.CurrentInteractable = null
		if visual != null:
			visual.material.set_shader_parameter("enabled", false)


func OnShutdown():
	pass

func OnInteract():
	pass
