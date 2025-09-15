extends Node2D

signal FocusChanged(Element : Control)
signal UIOpened(UI : FullscreenUI)
signal UIClosed(UI : FullscreenUI)

const AveragePixNullCharSize = 8

@export var Canvas : CanvasLayer
@export var GlobalUI : PackedScene
@export var LoadingScreenUI : PackedScene
@export var AlphaUnitSelection : PackedScene
@export var FormationUI : PackedScene
@export var CombatHUDUI : PackedScene
@export var MapRewardUI : PackedScene
@export var ExperienceUI : PackedScene
@export var AbilitySelectionUI : PackedScene
@export var UnitInspectionUI : PackedScene
@export var CSRUI : PackedScene
@export var CampsiteUIPrefab : PackedScene
@export var CampsiteRestedPopupPrefab : PackedScene
@export var TradeUIPrefab : PackedScene
@export var FullscreenNotifUI : PackedScene
@export var FullscreenConfirmPurchaseUI : PackedScene
@export var TeamManagementFullscreenUI : PackedScene


@export_category("Generics")
@export var Generic_32x32_Texture : PackedScene
@export var Generic_StatBlockEntry : PackedScene

var CurrentDetailedElement : DetailContainer
var CurrentInspectedElement : Control
var InspectActive : bool = false
var OpenUIs : Array[FullscreenUI]
var GlobalUIInstance : GlobalUIHelper
var LoadingScreenInstance : LoadingScreen
var HighestLevelUI : FullscreenUI


func _ready():
	get_viewport().gui_focus_changed.connect(OnNodeFocusedChanged)
	GlobalUIInstance = OpenFullscreenUI(GlobalUI)

func OnNodeFocusedChanged(_ctrl : Control):
	if _ctrl == null:
		return

	CurrentInspectedElement = _ctrl
	if InspectActive:
		CurrentDetailedElement.UpdateShowDetail(_ctrl)
	FocusChanged.emit(CurrentInspectedElement)

func _process(_delta: float) -> void:
	if CurrentInspectedElement == null || \
		(CurrentInspectedElement != null && !CurrentInspectedElement.is_visible_in_tree()) || \
		(CurrentInspectedElement != null && CurrentInspectedElement.focus_mode == Control.FocusMode.FOCUS_NONE):
		HighestLevelUI = GetHighestLevelVisibleUI()
		if HighestLevelUI != null:
			HighestLevelUI.ReturnFocus()
	else:
		if InputManager.infoDown:
			if CurrentInspectedElement is DetailContainer:
				if CurrentInspectedElement.Details.size() > 0:
					HighestLevelUI = GetHighestLevelVisibleUI()
					if HighestLevelUI != null:
						HighestLevelUI.StartShowDetails()

					CurrentDetailedElement = CurrentInspectedElement
					CurrentInspectedElement.BeginShowDetails()
					InspectActive = true

	if InputManager.cancelDown && InspectActive:
		CurrentDetailedElement.EndShowDetails()
		CurrentDetailedElement = null
		InspectActive = false
		HighestLevelUI = GetHighestLevelVisibleUI()
		if HighestLevelUI != null:
			HighestLevelUI.EndShowDetails()


func GetOffsetRequiredToKeepElementOnScreen(_element : Control):
	var offset : Vector2
	var viewportRect = get_viewport_rect()
	var elementRect = _element.get_global_rect()
	var elementPosition = elementRect.position
	var elementSize = elementRect.size
	if elementPosition.x + elementSize.x > viewportRect.size.x:
		offset.x = (elementPosition.x + elementSize.x) - viewportRect.size.x
	if elementPosition.y + elementSize.y > viewportRect.size.y:
		offset.y = (elementPosition.y + elementSize.y) - viewportRect.size.y
	return offset

func GetHighestLevelVisibleUI():
	for i in range(OpenUIs.size() - 1, -1, -1):
		var ui = OpenUIs[i]
		if ui == null:
			continue

		if ui.visible == false || !ui.TrackOnStack:
			continue

		return ui
	return null


func OnUIOpened(_ui : FullscreenUI):
	OpenUIs.append(_ui)
	CleanseNullUIs()
	if OpenUIs.size() > 0:
		OpenUIs.sort_custom(func(a : FullscreenUI, b : FullscreenUI): return a.Priority < b.Priority)
	InspectActive = false

	var parent = _ui.get_parent()
	if parent != Canvas:
		if parent == null:
			Canvas.add_child(_ui)
		else:
			_ui.reparent(Canvas)
		Canvas.move_child(_ui, OpenUIs.find(_ui))

	if CurrentInspectedElement != null:
		CurrentInspectedElement.release_focus()
		CurrentInspectedElement = null

	HighestLevelUI = GetHighestLevelVisibleUI()
	UIOpened.emit(_ui)

func OnUIClosed(_ui : FullscreenUI):
	InspectActive = false
	var index = OpenUIs.find(_ui)
	if index != -1:
		OpenUIs.remove_at(index)

	CleanseNullUIs()

	UIClosed.emit(_ui)

func CleanseNullUIs():
	# remove null uis
	for i in range(OpenUIs.size() - 1, -1, -1):
		if OpenUIs[i] == null:
			OpenUIs.remove_at(i)

func OpenFullscreenUI(_packedScene : PackedScene):
	var ui = _packedScene.instantiate() as FullscreenUI
	if ui == null || ui is not FullscreenUI:
		return null

	OnUIOpened(ui)
	return ui

func ShowResources(_refreshLabels : bool = true):
	if GlobalUIInstance != null:
		GlobalUIInstance.ShowResources(_refreshLabels)

func HideResources():
	if GlobalUIInstance != null:
		GlobalUIInstance.HideResources()

func CreateLoadingScreen():
	LoadingScreenInstance = OpenFullscreenUI(LoadingScreenUI)

func ShowLoadingScreen(_fadeTime = 1.5, lambda = null):
	if LoadingScreenInstance == null:
		CreateLoadingScreen()

	LoadingScreenInstance.ShowLoadingScreen(_fadeTime, lambda)
	return LoadingScreenInstance

func HideLoadingScreen(_fadeTime = 1.5, lambda = null):
	if LoadingScreenInstance == null:
		CreateLoadingScreen()

	LoadingScreenInstance.HideLoadingScreen(_fadeTime, lambda)
	return LoadingScreenInstance


static func AssignFocusNeighbors_Horizontal(_leftElement : Control, _rightElement : Control):
	_leftElement.focus_neighbor_right = _leftElement.get_path_to(_rightElement)
	_rightElement.focus_neighbor_left = _rightElement.get_path_to(_leftElement)

static func AssignFocusNeighbors_Vertical(_topElement : Control, _bottomElement : Control):
	_topElement.focus_neighbor_bottom = _topElement.get_path_to(_bottomElement)
	_bottomElement.focus_neighbor_top = _bottomElement.get_path_to(_topElement)
