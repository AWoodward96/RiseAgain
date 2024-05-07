extends Node2D
class_name PlayerController

signal OnTileChanged(_tile)
signal OnTileSelected(_tile)
signal OnCombatSequenceComplete()

@export var viewportTilePadding = 2
@onready var camera = $%MainCamera
@onready var reticle = %Reticle
@onready var movement_tracker : Line2D = %MovementTracker

var ControllerState : PlayerControllerState

var BlockMovementInput : bool
var CurrentTile : Tile :
	get:
		return currentGrid.GetTile(ConvertGlobalPositionToGridPosition())

var currentMap : Map
var currentGrid : Grid
var tileSize
var tileHalfSize

var trackingMovementOrigin

var selectedUnit : UnitInstance
var selectedAbility : AbilityInstance

# UIs
var formationUI
var combatHUD : CombatHUD

func Initialize(_map: Map):
	currentMap = _map
	currentGrid = _map.grid
	tileSize = _map.TileSize
	tileHalfSize = tileSize / 2
	UpdateCameraBounds()

func _process(_delta):
	if ControllerState != null :
		ControllerState._Execute(_delta)

func ChangeControllerState(a_newState : PlayerControllerState, optionalData):
	if ControllerState != null:
		ControllerState._Exit()

	print("Entering Controller State: ", a_newState.ToString())
	ControllerState = a_newState
	ControllerState._Enter(self, optionalData)

func ConvertGlobalPositionToGridPosition():
	return reticle.global_position / tileSize

func UpdateCameraBounds():
	var mapTotalSize = currentMap.GridSize * tileSize

	camera.limit_left = 0
	camera.limit_right = mapTotalSize.x
	camera.limit_top = 0
	camera.limit_bottom = mapTotalSize.y

func UpdateCameraPosition():
	var cameraPos = camera.global_position
	var viewportHalf = get_viewport_rect().size / 2
	viewportHalf -= Vector2(tileSize, tileSize) * viewportTilePadding

	var topleft = cameraPos - viewportHalf
	var bottomright = cameraPos + viewportHalf
	var move = Vector2.ZERO
	if reticle.global_position.x < topleft.x:
		move.x += reticle.global_position.x - topleft.x

	if reticle.global_position.x >= bottomright.x:
		# extra -1 tilesize because of indexing
		move.x += reticle.global_position.x - (bottomright.x - tileSize)

	if reticle.global_position.y < topleft.y:
		move.y += reticle.global_position.y - topleft.y

	if reticle.global_position.y >= bottomright.y:
		# extra -1 tilesize because of indexing
		move.y += reticle.global_position.y - (bottomright.y - tileSize)

	camera.global_position += move

func ForceReticlePosition(_gridPosition : Vector2i):
	reticle.global_position = _gridPosition * tileSize
	UpdateCameraPosition()
	OnTileChanged.emit(CurrentTile)

func ForceCameraPosition(_gridPosition : Vector2):
	camera.global_position = _gridPosition * tileSize
	UpdateCameraPosition()

func ClearSelectionData():
	selectedUnit = null
	currentGrid.ClearActions()

func EnterFormationState():
	var formationState = FormationControllerState.new()
	ChangeControllerState(formationState, null)
	return formationState.formationUI

func EnterSelectionState():
	ChangeControllerState(SelectionControllerState.new(), null)
	return CreateCombatHUD()

func EnterUnitMovementState():
	trackingMovementOrigin = selectedUnit.GridPosition
	ChangeControllerState(UnitMoveControllerState.new(), null)

	# Update the combat hud's inspector
	if combatHUD != null:
		combatHUD.HideInspectUI()

func EnterContextMenuState():
	ChangeControllerState(ContextControllerState.new(), null)

func EnterTargetingState(_targetData):
	ChangeControllerState(TargetingControllerState.new(), _targetData)

func EnterCombatState(_combatData):
	ChangeControllerState(CombatControllerState.new(), _combatData)

func CreateCombatHUD():
	if combatHUD == null:
		combatHUD = GameManager.CombatHUDUI.instantiate() as CombatHUD
		combatHUD.Initialize(currentMap, CurrentTile)
		add_child(combatHUD)
		combatHUD.ContextUI.ActionSelected.connect(OnActionSelected)
	return combatHUD

func OnActionSelected(_ability : AbilityInstance):
	if _ability == null:
		reticle.visible = true
		ForceReticlePosition(selectedUnit.GridPosition)
		selectedUnit.EndTurn()
		ClearSelectionData()
	else:
		# attempt to execute the ability
		selectedAbility = _ability
		selectedAbility.PollTargets()
