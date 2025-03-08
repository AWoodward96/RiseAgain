class_name PlayerControllerState

var ctrl : PlayerController
var currentMap : Map
var currentGrid : Grid
var reticle
var movementThisFrame : Vector2 = Vector2.ZERO

var lastMoveTimer = 0


func _Enter(_playerController : PlayerController, _data):
	ctrl = _playerController
	currentMap = ctrl.currentMap
	currentGrid = ctrl.currentGrid
	reticle = ctrl.reticle
	pass

func _Execute(_delta):
	UpdateInput(_delta)
	ctrl.UpdateCameraPosition()
	pass

func _Exit():
	pass

func UpdateInput(_delta):
	if ctrl.BlockMovementInput || CutsceneManager.BlockMovementInput:
		return

	# If you press a directional button, move in that direction
	# if you hold a directional button, move in that direction, and then after a certain amount of time
	#	start auto-moving in that direction really fast
	var tileSize = ctrl.tileSize
	movementThisFrame = Vector2.ZERO
	if InputManager.inputHeldTimer < InputManager.inputHeldThreshold:
		if InputManager.inputDown[0] : movementThisFrame.y -= 1
		if InputManager.inputDown[1] : movementThisFrame.x += 1
		if InputManager.inputDown[2] : movementThisFrame.y += 1
		if InputManager.inputDown[3] : movementThisFrame.x -= 1
		reticle.global_position += movementThisFrame * tileSize
	else:
		if InputManager.inputHeld[0] : movementThisFrame.y -= 1
		if InputManager.inputHeld[1] : movementThisFrame.x += 1
		if InputManager.inputHeld[2] : movementThisFrame.y += 1
		if InputManager.inputHeld[3] : movementThisFrame.x -= 1

		if lastMoveTimer > InputManager.inputHeldMoveTick:
			reticle.global_position += movementThisFrame * tileSize
			lastMoveTimer = 0

		lastMoveTimer += _delta

	var mapTotalSizeMinusOne = (currentMap.GridSize * tileSize) - Vector2i(tileSize, tileSize)
	if reticle.global_position.x < 0 : reticle.global_position.x = 0
	if reticle.global_position.y < 0 : reticle.global_position.y = 0
	if reticle.global_position.x > mapTotalSizeMinusOne.x : reticle.global_position.x = mapTotalSizeMinusOne.x
	if reticle.global_position.y > mapTotalSizeMinusOne.y : reticle.global_position.y = mapTotalSizeMinusOne.y

	var didMove = movementThisFrame != Vector2.ZERO
	if didMove:
		ctrl.CurrentTile = currentGrid.GetTile(ConvertGlobalPositionToGridPosition())
		ctrl.OnTileChanged.emit(ctrl.CurrentTile)

	return didMove

func ConvertGlobalPositionToGridPosition():
	return ctrl.ConvertGlobalPositionToGridPosition()

func ToString():
	return "PlayerControllerState_Base"

func ShowInspectUI():
	return true

func CanShowThreat():
	return true

func ShowObjective():
	return false
