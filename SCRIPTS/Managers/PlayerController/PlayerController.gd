extends Node2D
class_name PlayerController

signal OnTileChanged(_tile)
signal OnTileSelected(_tile)

@export var viewportTilePadding = 2
@export var floatingElementPadding = 4
@export var camera : Camera2D
@export var reticle : Node2D
@export var tutorialReticle : Node2D

@export var reticleMoveSound : FmodEventEmitter2D
@export var reticleSelectSound : FmodEventEmitter2D
@export var reticleCancelSound : FmodEventEmitter2D
@export var toggleThreat : FmodEventEmitter2D

@onready var movement_tracker : Line2D = %MovementTracker
@onready var movement_preview_sprite: Sprite2D = %MovementPreviewSprite
@onready var grid_entity_preview_sprite: Sprite2D = %GridEntityPreviewSprite
@onready var vis_top_left: Sprite2D = $VisTopLeft
@onready var vis_bottom_right: Sprite2D = $VisBottomRight
@onready var desired_camera_pos: Sprite2D = $DesiredCameraPos

var ControllerState : PlayerControllerState
var ReticleQuintet : Control.LayoutPreset
var CameraMovementComplete : bool

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
var selectedItem : UnitUsable

var unitInventoryOpen : bool

var desiredCameraPosition : Vector2 = Vector2(0,0)

var lastItemFilter
var totalMapSize

# UIs
var formationUI
var combatHUD : CombatHUD
var inspectUI : UnitInspectUI

var forcedTileSelection : Tile
var forcedContextOption : int = -1

func Initialize(_map: Map):
	currentMap = _map
	currentGrid = _map.grid
	tileSize = _map.TileSize
	tileHalfSize = tileSize / 2
	UpdateCameraBounds()


	# Both of these methods just refresh the objective ui
	currentMap.OnUnitTurnEnd.connect(UnitTurnEnd)
	currentMap.OnUnitDied.connect(UnitDied)

func _process(_delta):
	if CSR.Open:
		return

	if combatHUD != null:
		combatHUD.ObjectivePanelUI.Disabled = !ControllerState.ShowObjective()

	# We block out the execution if inspect ui is not equal to null - this is hacky but it works
	if ControllerState != null && inspectUI == null:
		ControllerState._Execute(_delta)

	if ControllerState != null && ControllerState.CanShowThreat():
		if InputManager.infoDown && !CutsceneManager.BlockInspectInput:
			# ShowInspectUI() check is also reffering to the hanging ui element in the combat hud
			# If this behavior needs to be split - then do that but for now it actually works out fine
			if CurrentTile.Occupant != null && ControllerState.ShowInspectUI():
				if !CurrentTile.Occupant.Submerged || (CurrentTile.Occupant.Submerged && CurrentTile.Occupant.UnitAllegiance == GameManager.GameSettings.TeamID.ALLY):
					if inspectUI == null:
						inspectUI = UnitInspectUI.Show(CurrentTile.Occupant)
			else:
				currentGrid.ShowThreat(!currentGrid.ShowingThreat, currentMap.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ENEMY))
				if toggleThreat != null:
					toggleThreat.play()

	if InputManager.cancelDown && inspectUI != null:
		inspectUI.queue_free()
		inspectUI = null

	camera.global_position = camera.global_position.lerp(desiredCameraPosition, 1.0 - exp(-_delta * Juice.cameraMoveSpeed))
	CameraMovementComplete = camera.global_position.distance_to(desiredCameraPosition) < 0.1

func ChangeControllerState(a_newState : PlayerControllerState, optionalData):
	if ControllerState != null:
		ControllerState._Exit()

	print("Entering Controller State: ", a_newState.ToString())
	ControllerState = a_newState
	ControllerState._Enter(self, optionalData)

func ConvertGlobalPositionToGridPosition():
	return reticle.global_position / tileSize

func UpdateCameraBounds():
	totalMapSize = currentMap.GridSize * tileSize

	camera.limit_left = 0
	camera.limit_right = totalMapSize.x
	camera.limit_top = 0
	camera.limit_bottom = totalMapSize.y

func UpdateCameraPosition():
	if !is_inside_tree():
		return

	var cameraPos = desiredCameraPosition
	var viewportHalf = get_viewport_rect().size / 2
	var viewportHalfMinusPadding = viewportHalf - (Vector2(tileSize, tileSize) * viewportTilePadding)

	var topleft = cameraPos - viewportHalfMinusPadding
	var bottomright = cameraPos + viewportHalfMinusPadding
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
	desiredCameraPosition.x = clamp(desiredCameraPosition.x, 0 + viewportHalf.x, totalMapSize.x - viewportHalf.x)
	desiredCameraPosition.y = clamp(desiredCameraPosition.y, 0 + viewportHalf.y, totalMapSize.y - viewportHalf.y)
	desired_camera_pos.global_position = desiredCameraPosition
	#UpdateReticleQuintant()

func IsReticleInLeftHalfOfViewport():
	return reticle.global_position.x < desiredCameraPosition.x

func UpdateReticleQuintant():
	# Basically, if the reticle is in the corners (determined by floatingElementPadding), return which corner it's in
	# If it's not in a corner, return that it's in the Center somewhere
	var viewportHalf = get_viewport_rect().size / 2
	var viewportHalfMinusPadding = viewportHalf - (Vector2(tileSize, tileSize) * floatingElementPadding)

	var topleft = desiredCameraPosition - viewportHalfMinusPadding
	var bottomright = desiredCameraPosition + viewportHalfMinusPadding
	bottomright.x = clamp(bottomright.x, 0 + viewportHalfMinusPadding.x, totalMapSize.x - viewportHalfMinusPadding.x)
	bottomright.y = clamp(bottomright.y, 0 + viewportHalfMinusPadding.y, totalMapSize.y - viewportHalfMinusPadding.y)

	vis_top_left.global_position = topleft
	vis_bottom_right.global_position = bottomright

	if reticle.global_position.x <= topleft.x:
		# Left side
		if reticle.global_position.y <= topleft.y:
			# We're in the top left
			ReticleQuintet = Control.PRESET_TOP_LEFT
			return

		if reticle.global_position.y >= bottomright.y:
			ReticleQuintet = Control.PRESET_BOTTOM_LEFT
			return

	if reticle.global_position.x >= bottomright.x:
		if reticle.global_position.y <= topleft.y:
			# We're in the top left
			ReticleQuintet = Control.PRESET_TOP_RIGHT
			return

		if reticle.global_position.y >= bottomright.y:
			ReticleQuintet = Control.PRESET_BOTTOM_RIGHT
			return

	ReticleQuintet = Control.PRESET_CENTER

func ForceReticlePosition(_gridPosition : Vector2i):
	reticle.scale = Vector2(1, 1)
	reticle.global_position = _gridPosition * tileSize
	UpdateCameraPosition()
	OnTileChanged.emit(CurrentTile)

func FocusReticleOnUnit(_unit : UnitInstance):
	if _unit == null:
		reticle.scale = Vector2(1, 1)
		return

	reticle.scale = Vector2(_unit.Template.GridSize,_unit.Template.GridSize)
	reticle.global_position = _unit.CurrentTile.Position * tileSize
	UpdateCameraPosition()
	OnTileChanged.emit(CurrentTile)

func ForceCameraPosition(_gridPosition : Vector2, _instantaneous : bool = false):
	CameraMovementComplete = false
	reticle.global_position = _gridPosition * tileSize
	desiredCameraPosition = _gridPosition * tileSize
	if _instantaneous:
		camera.global_position = _gridPosition * tileSize
	UpdateCameraPosition()

func ClearSelectionData():
	selectedUnit = null
	currentGrid.ClearActions()

func EnterFormationState():
	var formationState = FormationControllerState.new()
	ChangeControllerState(formationState, null)
	return formationState.formationUI

func EnterCampsiteState():
	var campsiteState = CampsiteControllerState.new()
	ChangeControllerState(campsiteState, null)

func EnterCutsceneState():
	var cutsceneState = CutsceneControllerState.new()
	ChangeControllerState(cutsceneState, null)

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

func EnterTargetingState(_itemOrAbility):
	ChangeControllerState(TargetingControllerState.new(), _itemOrAbility)

func EnterItemSelectionState(_filterForInventory):
	lastItemFilter = _filterForInventory
	ChangeControllerState(ItemSelectControllerState.new(), _filterForInventory)

func EnterUnitStackClearState(_unitInstance : UnitInstance):
	ChangeControllerState(UnitStackClearControllerState.new(), _unitInstance)

func EnterEndGameState():
	ChangeControllerState(EndGameControllerState.new(), null)

func EnterActionExecutionState(_log):
	ChangeControllerState(ActionExecutionState.new(), _log)

func EnterGlobalContextState():
	ChangeControllerState(GlobalContextControllerState.new(), null)

func CreateCombatHUD():
	if combatHUD == null:
		combatHUD = UIManager.CombatHUDUI.instantiate() as CombatHUD
		combatHUD.Initialize(currentMap, CurrentTile)
		add_child(combatHUD)

	return combatHUD

func UpdateGlobalContextUI():
	combatHUD.ContextUI.Clear()
	combatHUD.ContextUI.AddButton("End Turn", true, OnEndTurn)


func UpdateContextUI():
	combatHUD.ContextUI.Clear()

	var optionCount = 0
	var forcedOption = -1
	if CutsceneManager.active_cutscene != null:
		forcedOption = forcedContextOption

	var currentTile = selectedUnit.CurrentTile
	# First do any special actions
	for ge in currentTile.GridEntities:
		if ge is GEChest:
			if !ge.claimed:
				combatHUD.ContextUI.AddButton(GameManager.LocalizationSettings.openChestAction, true, OnUnlock)


	# Then the weapon
	if !CutsceneManager.BlockWeaponContextMenuOption:
		if selectedUnit.EquippedWeapon != null:
			var enabled = forcedOption == -1 || forcedOption == 0
			combatHUD.ContextUI.AddAbilityButton(selectedUnit.EquippedWeapon, enabled, OnAttack)
			optionCount += 1



	# Then do the standard abilities
	if !CutsceneManager.BlockAbilityContextMenuOption:
		for ability in selectedUnit.Abilities:
			if ability.type == Ability.AbilityType.Standard:
				# Block if focus cost can't be met - or if the ability has a limited usage
				var canCast = (selectedUnit.currentFocus >= ability.focusCost || CSR.AllAbilitiesCost0)
				canCast = canCast && (ability.limitedUsage == -1 || (ability.limitedUsage != -1 && ability.remainingUsages > 0))
				canCast = canCast && (forcedOption == -1 || (forcedOption != -1 && forcedOption == optionCount))
				combatHUD.ContextUI.AddAbilityButton(ability, canCast, OnAbility.bind(ability))
				optionCount += 1

	# Then do tacticals
	if !CutsceneManager.BlockTacticalContextMenuOption:
		for ability in selectedUnit.Abilities:
			if ability.type == Ability.AbilityType.Tactical:
				# Block if focus cost can't be met - or if the ability has a limited usage
				var canCast = (selectedUnit.currentFocus >= ability.focusCost || CSR.AllAbilitiesCost0)
				canCast = canCast && (ability.limitedUsage == -1 || (ability.limitedUsage != -1 && ability.remainingUsages > 0))
				canCast = canCast && (forcedOption == -1 || (forcedOption != -1 && forcedOption == optionCount))
				combatHUD.ContextUI.AddAbilityButton(ability, canCast, OnAbility.bind(ability))
				optionCount += 1


	var canWait = !CutsceneManager.BlockWaitContextMenuOption
	canWait = canWait && (forcedOption == -1 || (forcedOption != -1 && forcedOption == optionCount))
	combatHUD.ContextUI.AddButton(GameManager.LocalizationSettings.waitAction, canWait, OnWait)
	combatHUD.ContextUI.LoopButtons()
	combatHUD.ContextUI.SelectFirst()

func OnWait():
	reticle.visible = true
	ForceReticlePosition(selectedUnit.GridPosition)
	selectedUnit.EndTurn()
	ClearSelectionData()
	EnterSelectionState()

func OnUnlock():
	# First do any special actions
	for ge in selectedUnit.CurrentTile.GridEntities:
		if ge is GEChest:
			ge.Claim(selectedUnit)

	selectedUnit.QueueEndTurn()
	ClearSelectionData()
	EnterSelectionState()

func OnInventory():
	if selectedUnit != null:
		var ui = UIManager.UnitInventoryUI.instantiate()
		add_child(ui)
		ui.Initialize(selectedUnit)

		if !ui.OnClose.is_connected(OnInventoryClose):
			ui.OnClose.connect(OnInventoryClose)
		unitInventoryOpen = true
	pass

func OnEndTurn():
	var units = currentMap.GetUnitsOnTeam(GameSettingsTemplate.TeamID.ALLY)
	for u in units:
		if u.Activated && u.IsStackFree:
			u.QueueEndTurn()

func OnInventoryClose():
	unitInventoryOpen = false
	currentGrid.ClearActions()
	combatHUD.ShowContext()

func OnDefend():
	selectedUnit.Defend()
	OnWait()

func CanAttack(_unit : UnitInstance):
	if _unit == null:
		return false

	return _unit.EquippedWeapon != null

func PreviewGridEntity(_gridEntityPackedScene : PackedScene):
	var instantiate = _gridEntityPackedScene.instantiate() as GridEntityBase
	grid_entity_preview_sprite.visible = true
	grid_entity_preview_sprite.texture = instantiate.PreviewSprite
	pass

func CancelGridEntityPreview():
	grid_entity_preview_sprite.visible = false

func RefreshObjectives():
	if combatHUD != null:
		combatHUD.UpdateObjectives()

func UnitTurnEnd(_unit : UnitInstance):
	RefreshObjectives()

func UnitDied(_unit :UnitInstance, _result : DamageStepResult):
	RefreshObjectives()

func OnAttack():
	selectedItem = selectedUnit.EquippedWeapon
	EnterTargetingState(selectedItem)

func OnAbility(_ability : Ability):
	EnterTargetingState(_ability)

func ShowTutorialReticle(_pos : Vector2i):
	tutorialReticle.visible = true
	tutorialReticle.global_position = _pos * currentGrid.CellSize
	pass

func HideTutorialReticle():
	tutorialReticle.visible = false
