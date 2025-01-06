extends CharacterBody2D
class_name TopDownPlayer

static var CurrentInteractable : TopdownInteractable
static var BlockInputCounter : int = 0

@export var maximumSpeed : float = 96
@export var camera : Camera2D

var currentEnvironment : TopdownEnvironment

func Initialize(_environment : TopdownEnvironment):
	currentEnvironment = _environment
	UpdateCameraBounds()

func UpdateCameraBounds():
	var totalMapSize = currentEnvironment.size * currentEnvironment.tileSize

	camera.limit_left = 0
	camera.limit_right = totalMapSize.x
	camera.limit_top = 0
	camera.limit_bottom = totalMapSize.y
	pass

func _process(_delta):
	if BlockInputCounter > 0:
		return

	Move(_delta)
	if CurrentInteractable != null && InputManager.selectDown:
		CurrentInteractable.OnInteract()
	pass

func Move(_delta):
	# It's really that easy!
	var desiredVelocity = Vector2(InputManager.topdownHorizontal, InputManager.topdownVertical).normalized() * maximumSpeed

	# writing it like this just in case I ever wantbtw  to modify desired velocity before assigning
	velocity = desiredVelocity

	# NOTE: Move and slize already uses DeltaTime - NO NEED TO MULTIPLY BY THAT AGAIN
	move_and_slide()
