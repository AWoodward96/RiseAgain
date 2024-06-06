extends Node2D
class_name PlayerController

signal OnTileChanged(_tile)
signal OnTileSelected(_tile)
signal OnCombatSequenceComplete()

@export var viewportTilePadding = 2
@export var camera : Camera2D
@export var reticle : Node2D

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
var selectedItem : Item

var unitInventoryOpen : bool

var desiredCameraPosition : Vector2 = Vector2(0,0)

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

	camera.global_position = camera.global_position.lerp(desiredCameraPosition, 1.0 - exp(-_delta * Juice.cameraMoveSpeed))

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
	if !is_inside_tree():
		return

	var cameraPos = desiredCameraPosition
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

	desiredCameraPosition += move

func IsReticleInLeftHalfOfViewport():
	return reticle.global_position.x < desiredCameraPosition.x

func ForceReticlePosition(_gridPosition : Vector2i):
	reticle.global_position = _gridPosition * tileSize
	UpdateCameraPosition()
	OnTileChanged.emit(CurrentTile)

func ForceCameraPosition(_gridPosition : Vector2):
	camera.global_position = _gridPosition * tileSize
	desiredCameraPosition = _gridPosition * tileSize
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

func EnterOffTurnState():
	ChangeControllerState(OffTurnControllerState.new(), null)

func EnterContextMenuState():
	ChangeControllerState(ContextControllerState.new(), null)

func EnterTargetingState(_targetData):
	ChangeControllerState(TargetingControllerState.new(), _targetData)

func EnterCombatState(_combatData):
	ChangeControllerState(CombatControllerState.new(), _combatData)

func EnterItemSelectionState():
	ChangeControllerState(ItemSelectControllerState.new(), null)

func EnterUnitStackClearState(_unitInstance : UnitInstance):
	ChangeControllerState(UnitStackClearControllerState.new(), _unitInstance)

func CreateCombatHUD():
	if combatHUD == null:
		combatHUD = GameManager.CombatHUDUI.instantiate() as CombatHUD
		combatHUD.Initialize(currentMap, CurrentTile)
		add_child(combatHUD)

		combatHUD.ContextUI.OnWait.connect(OnWait)
		combatHUD.ContextUI.OnDefend.connect(OnDefend)
		combatHUD.ContextUI.OnAttack.connect(OnAttack)
		combatHUD.ContextUI.OnInventory.connect(OnInventory)

		combatHUD.itemSelectUI.OnItemSelectedForCombat.connect(OnItemSelectedForCombat)

	return combatHUD

func OnWait():
	reticle.visible = true
	ForceReticlePosition(selectedUnit.GridPosition)
	selectedUnit.EndTurn()
	ClearSelectionData()
	EnterSelectionState()

func OnInventory():
	if selectedUnit != null:
		var ui = GameManager.UnitInventoryUI.instantiate()
		add_child(ui)
		ui.Initialize(selectedUnit)

		if !ui.OnClose.is_connected(OnInventoryClose):
			ui.OnClose.connect(OnInventoryClose)
		unitInventoryOpen = true
	pass

func OnInventoryClose():
	unitInventoryOpen = false
	currentGrid.ClearActions()
	combatHUD.ShowContext(selectedUnit)


func OnDefend():
	selectedUnit.Defend()
	OnWait()

func OnAttack():
	EnterItemSelectionState()

func OnItemSelectedForCombat(_item : Item):
	if _item != null:
		selectedItem = _item
		selectedUnit.EquipItem(selectedItem)
		selectedItem.PollTargets()
