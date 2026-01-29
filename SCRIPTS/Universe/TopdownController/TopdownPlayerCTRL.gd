extends CharacterBody2D
class_name TopDownPlayer

static var CurrentInteractable : TopdownInteractable
static var BlockInputCounter : int = 0

@export var maximumSpeed : float = 448
@export var camera : Camera2D

var currentEnvironment : TopdownEnvironment
var teleporting : bool

func Initialize(_environment : TopdownEnvironment):
	currentEnvironment = _environment
	UpdateCameraBounds()

func UpdateCameraBounds():
	var totalMapSize = currentEnvironment.size * currentEnvironment.tileSize
	var mapOffset = currentEnvironment.offset * currentEnvironment.tileSize

	camera.limit_left = mapOffset.x
	camera.limit_right = totalMapSize.x + mapOffset.x
	camera.limit_top = mapOffset.y
	camera.limit_bottom = totalMapSize.y + mapOffset.y
	camera.reset_smoothing()
	pass

func _process(_delta):
	if BlockInputCounter > 0:
		return
	elif BlockInputCounter < 0:
		BlockInputCounter = 0

	Move()
	if CurrentInteractable != null && InputManager.selectDown:
		CurrentInteractable.OnInteract()
	pass

func Move():
	# It's really that easy!
	var desiredVelocity = Vector2(InputManager.topdownHorizontal, InputManager.topdownVertical).normalized() * maximumSpeed

	# writing it like this just in case I ever wantbtw  to modify desired velocity before assigning
	velocity = desiredVelocity

	# NOTE: Move and slize already uses DeltaTime - NO NEED TO MULTIPLY BY THAT AGAIN
	move_and_slide()

func UseTeleporter(_tp : TopdownTeleporter):
	if _tp == null || _tp.Destination == null || teleporting:
		return

	BlockInputCounter += 1
	teleporting = true

	# lambdas op
	UIManager.ShowLoadingScreen(0.5, func() :
		position = _tp.Destination.global_position
		if _tp.DestinationEnvironment != null:
			currentEnvironment = _tp.DestinationEnvironment
			UpdateCameraBounds()

		await get_tree().create_timer(0.5).timeout

		#camera.reset_smoothing()
		# lambda inside of lambda, what's good
		UIManager.HideLoadingScreen(0.3, func():
			BlockInputCounter -= 1
			teleporting = false
			)
		)

	pass
